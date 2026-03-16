const express = require('express');
const router = express.Router();
const { supabaseAdmin } = require('../utils/supabase');
const { authenticate } = require('../middleware/auth');
const { generateKundali } = require('../services/astronomical-engine');
const { logger } = require('../utils/logger');

router.post('/generate', authenticate, async (req, res) => {
  try {
    const { name, date_of_birth, time_of_birth, latitude, longitude, timezone, place_name, country, ayanamsa } = req.body;
    if (!date_of_birth || !time_of_birth || latitude == null || longitude == null || !timezone)
      return res.status(400).json({ error: 'Missing required birth data' });

    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    if (!profile) return res.status(404).json({ error: 'User not found' });

    const { data: bd } = await supabaseAdmin.from('birth_data').insert({
      user_id: profile.id, name: name || 'My Kundali',
      date_of_birth, time_of_birth, latitude, longitude, timezone,
      place_name, country, ayanamsa: ayanamsa || 'lahiri'
    }).select().single();

    const chart = generateKundali({ date_of_birth, time_of_birth, latitude, longitude, timezone, ayanamsa: ayanamsa || 'lahiri' });

    const { data: kundali } = await supabaseAdmin.from('kundalis').insert({
      birth_data_id: bd.id, user_id: profile.id,
      ayanamsa_used: chart.meta.ayanamsa_used, ayanamsa_value: chart.meta.ayanamsa_value,
      sidereal_time: chart.meta.sidereal_time, julian_day: chart.meta.julian_day,
      ascendant_longitude: chart.ascendant.longitude,
      ascendant_rashi: chart.ascendant.rashi, ascendant_nakshatra: chart.ascendant.nakshatra,
      ascendant_nakshatra_pada: chart.ascendant.nakshatra_pada,
      chart_data: chart, divisional_charts: chart.divisional_charts, engine_version: chart.meta.engine_version
    }).select().single();

    // Store planet positions
    await supabaseAdmin.from('planet_positions').insert(
      Object.values(chart.planets).map(p => ({
        kundali_id: kundali.id, planet: p.planet, longitude: p.longitude,
        rashi: p.rashi, rashi_degree: p.rashi_degree,
        nakshatra: p.nakshatra, nakshatra_pada: p.nakshatra_pada,
        nakshatra_lord: p.nakshatra_lord, house_number: p.house_number,
        dignity: p.dignity, is_retrograde: p.is_retrograde
      }))
    );

    // Store house cusps
    await supabaseAdmin.from('house_cusps').insert(
      chart.houses.map(h => ({
        kundali_id: kundali.id, house_number: h.house_number,
        cusp_longitude: h.cusp_longitude, rashi: h.rashi,
        lord: h.lord, sign_lord: h.sign_lord, star_lord: h.star_lord
      }))
    );

    // Store yogas
    if (chart.yogas.length)
      await supabaseAdmin.from('yogas').insert(chart.yogas.map(y => ({
        kundali_id: kundali.id, yoga_name: y.yoga_name, yoga_type: y.yoga_type,
        forming_planets: y.forming_planets, forming_houses: y.forming_houses,
        strength: y.strength, description: y.description,
        source_tradition: y.source_tradition, source_text: y.source_text
      })));

    // Store Maha dashas
    const mahas = chart.dashas.filter(d => d.level === 'maha').slice(0, 18);
    if (mahas.length)
      await supabaseAdmin.from('dashas').insert(mahas.map(d => ({
        kundali_id: kundali.id, dasha_system: 'vimshottari', level: d.level,
        planet: d.planet, start_date: d.start_date, end_date: d.end_date, duration_years: d.duration_years
      })));

    res.status(201).json({ kundali_id: kundali.id, birth_data_id: bd.id, chart });
  } catch (err) { logger.error('Kundali gen error:', err); res.status(500).json({ error: 'Failed to generate kundali' }); }
});

router.get('/list', authenticate, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const { data } = await supabaseAdmin.from('kundalis')
      .select('id, ascendant_rashi, ascendant_nakshatra, computed_at, birth_data(name, date_of_birth, place_name)')
      .eq('user_id', profile.id).order('computed_at', { ascending: false });
    res.json({ kundalis: data });
  } catch (err) { res.status(500).json({ error: 'Failed to list kundalis' }); }
});

router.get('/:id', authenticate, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    const { data: kundali } = await supabaseAdmin.from('kundalis')
      .select('*, birth_data(*), planet_positions(*), house_cusps(*), yogas(*), dashas(*)')
      .eq('id', req.params.id).eq('user_id', profile.id).single();
    if (!kundali) return res.status(404).json({ error: 'Kundali not found' });
    res.json({ kundali });
  } catch (err) { res.status(500).json({ error: 'Failed to fetch kundali' }); }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin.from('users').select('id').eq('auth_id', req.user.id).single();
    await supabaseAdmin.from('kundalis').delete().eq('id', req.params.id).eq('user_id', profile.id);
    res.json({ message: 'Kundali deleted' });
  } catch (err) { res.status(500).json({ error: 'Failed to delete' }); }
});

module.exports = router;
