/**
 * JYOTISH AI — Astronomical Calculation Engine
 *
 * Sidereal calculations: planetary longitudes, ascendant, houses,
 * 27 nakshatras, Vimshottari dasha, divisional charts, yoga detection.
 * Supports Lahiri / Raman / KP ayanamsa for any global location.
 */

const moment = require('moment-timezone');
const { logger } = require('../utils/logger');

// ── Constants ────────────────────────────────────────────

const RASHIS = [
  'Aries','Taurus','Gemini','Cancer','Leo','Virgo',
  'Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'
];
const RASHI_LORDS = [
  'mars','venus','mercury','moon','sun','mercury',
  'venus','mars','jupiter','saturn','saturn','jupiter'
];

const NAKSHATRAS = [
  { name:'Ashwini',            lord:'ketu',    deity:'Ashwini Kumaras' },
  { name:'Bharani',            lord:'venus',   deity:'Yama' },
  { name:'Krittika',           lord:'sun',     deity:'Agni' },
  { name:'Rohini',             lord:'moon',    deity:'Brahma' },
  { name:'Mrigashira',         lord:'mars',    deity:'Soma' },
  { name:'Ardra',              lord:'rahu',    deity:'Rudra' },
  { name:'Punarvasu',          lord:'jupiter', deity:'Aditi' },
  { name:'Pushya',             lord:'saturn',  deity:'Brihaspati' },
  { name:'Ashlesha',           lord:'mercury', deity:'Sarpa' },
  { name:'Magha',              lord:'ketu',    deity:'Pitris' },
  { name:'Purva Phalguni',     lord:'venus',   deity:'Bhaga' },
  { name:'Uttara Phalguni',    lord:'sun',     deity:'Aryaman' },
  { name:'Hasta',              lord:'moon',    deity:'Savitar' },
  { name:'Chitra',             lord:'mars',    deity:'Tvastar' },
  { name:'Swati',              lord:'rahu',    deity:'Vayu' },
  { name:'Vishakha',           lord:'jupiter', deity:'Indragni' },
  { name:'Anuradha',           lord:'saturn',  deity:'Mitra' },
  { name:'Jyeshtha',           lord:'mercury', deity:'Indra' },
  { name:'Mula',               lord:'ketu',    deity:'Nritti' },
  { name:'Purva Ashadha',      lord:'venus',   deity:'Apas' },
  { name:'Uttara Ashadha',     lord:'sun',     deity:'Vishvadevas' },
  { name:'Shravana',           lord:'moon',    deity:'Vishnu' },
  { name:'Dhanishtha',         lord:'mars',    deity:'Vasu' },
  { name:'Shatabhisha',        lord:'rahu',    deity:'Varuna' },
  { name:'Purva Bhadrapada',   lord:'jupiter', deity:'Ajaikapada' },
  { name:'Uttara Bhadrapada',  lord:'saturn',  deity:'Ahirbudhnya' },
  { name:'Revati',             lord:'mercury', deity:'Pushan' }
];

const VIMSHOTTARI_YEARS = {
  ketu:7, venus:20, sun:6, moon:10, mars:7,
  rahu:18, jupiter:16, saturn:19, mercury:17
};
const VIMSHOTTARI_ORDER = ['ketu','venus','sun','moon','mars','rahu','jupiter','saturn','mercury'];

const AYANAMSA_VALUES = {
  lahiri:          { epoch: 23.853333, rate: 0.01396667 },
  raman:           { epoch: 22.460000, rate: 0.01396667 },
  krishnamurti:    { epoch: 23.763333, rate: 0.01396667 },
  yukteshwar:      { epoch: 22.460000, rate: 0.01396667 },
  true_chitrapaksha:{ epoch: 23.853333, rate: 0.01396667 }
};

const EXALTATION   = { sun:10, moon:33, mars:298, mercury:165, jupiter:95, venus:357, saturn:200 };
const DEBILITATION = { sun:190, moon:213, mars:118, mercury:345, jupiter:275, venus:177, saturn:20 };
const OWN_SIGNS    = { sun:[4], moon:[3], mars:[0,7], mercury:[2,5], jupiter:[8,11], venus:[1,6], saturn:[9,10] };
const MOOLATRIKONA = {
  sun:     { sign:4, from:0, to:20 },
  moon:    { sign:1, from:3, to:30 },
  mars:    { sign:0, from:0, to:12 },
  mercury: { sign:5, from:15,to:20 },
  jupiter: { sign:8, from:0, to:10 },
  venus:   { sign:6, from:0, to:15 },
  saturn:  { sign:10,from:0, to:20 }
};

const PLANET_NAMES = ['sun','moon','mercury','venus','mars','jupiter','saturn'];

// ── Core Astronomical Functions ──────────────────────────

function dateToJulianDay(year, month, day, hour) {
  if (month <= 2) { year -= 1; month += 12; }
  const A = Math.floor(year / 100);
  const B = 2 - A + Math.floor(A / 4);
  return Math.floor(365.25 * (year + 4716)) +
         Math.floor(30.6001 * (month + 1)) +
         day + hour / 24.0 + B - 1524.5;
}

function greenwichSiderealTime(jd) {
  const T = (jd - 2451545.0) / 36525.0;
  let gst = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
            0.000387933 * T * T - T * T * T / 38710000.0;
  return ((gst % 360) + 360) % 360;
}

function localSiderealTime(jd, longitude) {
  return (greenwichSiderealTime(jd) + longitude + 360) % 360;
}

function calculateAyanamsa(jd, system = 'lahiri') {
  const T = (jd - 2451545.0) / 36525.0;
  const cfg = AYANAMSA_VALUES[system] || AYANAMSA_VALUES.lahiri;
  return cfg.epoch + cfg.rate * T * 100;
}

/**
 * Simplified mean-element planetary longitudes.
 * For sub-arcminute accuracy swap with Swiss Ephemeris bindings.
 */
function calculatePlanetaryLongitudes(jd) {
  const T = (jd - 2451545.0) / 36525.0;
  const pos = {};

  // Sun
  const sunL = (280.46646 + 36000.76983 * T + 0.0003032 * T * T) % 360;
  const sunM = (357.52911 + 35999.05029 * T - 0.0001537 * T * T) % 360;
  const sunMR = sunM * Math.PI / 180;
  const sunEq = (1.914602 - 0.004817 * T) * Math.sin(sunMR)
              + (0.019993 - 0.000101 * T) * Math.sin(2 * sunMR)
              + 0.000289 * Math.sin(3 * sunMR);
  pos.sun = ((sunL + sunEq) % 360 + 360) % 360;

  // Moon
  const mL = (218.3165 + 481267.8813 * T) % 360;
  const mD = (297.8502 + 445267.1115 * T) % 360;
  const mM = (134.9634 + 477198.8676 * T) % 360;
  pos.moon = ((mL + 6.289 * Math.sin(mM * Math.PI / 180)
             + 1.274 * Math.sin((2 * mD - mM) * Math.PI / 180)
             + 0.658 * Math.sin(2 * mD * Math.PI / 180)) % 360 + 360) % 360;

  // Simplified mean longitudes for outer planets
  pos.mercury  = ((sunL + 48.331 + 4.0923344368 * T * 365.25) % 360 + 360) % 360;
  pos.venus    = ((181.979801 + 58517.8156760 * T) % 360 + 360) % 360;
  pos.mars     = ((355.433275 + 19140.2993313 * T) % 360 + 360) % 360;
  pos.jupiter  = ((34.351484  + 3034.9056746  * T) % 360 + 360) % 360;
  pos.saturn   = ((50.077471  + 1222.1137943  * T) % 360 + 360) % 360;
  pos.rahu     = ((125.0445479 - 1934.1362891 * T) % 360 + 360) % 360;
  pos.ketu     = (pos.rahu + 180) % 360;

  return pos;
}

function calculateAscendant(lst, latitude) {
  const lstR = lst * Math.PI / 180;
  const latR = latitude * Math.PI / 180;
  const obl  = 23.4393 * Math.PI / 180;
  const y = -Math.cos(lstR);
  const x = Math.sin(obl) * Math.tan(latR) + Math.cos(obl) * Math.sin(lstR);
  return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
}

function calculateHouseCusps(ascendant) {
  return Array.from({ length: 12 }, (_, i) => (ascendant + i * 30) % 360);
}

// ── Rashi / Nakshatra / Dignity ──────────────────────────

function getRashi(longitude) {
  const i = Math.floor(((longitude % 360) + 360) % 360 / 30);
  return { index: i, name: RASHIS[i], lord: RASHI_LORDS[i], degree: longitude % 30 };
}

function getNakshatra(longitude) {
  const span = 360 / 27;
  const i = Math.floor(((longitude % 360) + 360) % 360 / span);
  const within = longitude - i * span;
  const pada = Math.floor(within / (span / 4)) + 1;
  return { index: i, ...NAKSHATRAS[i], pada, degree: within };
}

function getPlanetDignity(planet, longitude) {
  if (!OWN_SIGNS[planet]) return 'neutral';
  const rashi = getRashi(longitude);
  const si = rashi.index;
  if (Math.abs(longitude - EXALTATION[planet]) < 10) return 'exalted';
  if (Math.abs(longitude - DEBILITATION[planet]) < 10) return 'debilitated';
  const mt = MOOLATRIKONA[planet];
  if (mt && si === mt.sign && rashi.degree >= mt.from && rashi.degree <= mt.to) return 'moolatrikona';
  if (OWN_SIGNS[planet].includes(si)) return 'own';
  // Simplified friendship
  const friendMap = {
    sun:[3,4,8,11], moon:[2,5], mars:[3,4,8,11], mercury:[1,6],
    jupiter:[0,3,4], venus:[2,5,6,9,10], saturn:[2,5,6]
  };
  const enemyMap = {
    sun:[1,6,9,10], moon:[], mars:[2,5], mercury:[3],
    jupiter:[2,5], venus:[0,3], saturn:[0,3,4]
  };
  const lordIdx = PLANET_NAMES.indexOf(RASHI_LORDS[si]);
  if (friendMap[planet]?.includes(lordIdx)) return 'friend';
  if (enemyMap[planet]?.includes(lordIdx)) return 'enemy';
  return 'neutral';
}

function getHouseNumber(planetLong, cusps) {
  for (let i = 0; i < 12; i++) {
    const s = cusps[i], e = cusps[(i + 1) % 12];
    if (s < e) { if (planetLong >= s && planetLong < e) return i + 1; }
    else       { if (planetLong >= s || planetLong < e) return i + 1; }
  }
  return 1;
}

// ── Vimshottari Dasha ────────────────────────────────────

function calculateVimshottariDasha(moonLongitude, birthDate) {
  const nak = getNakshatra(moonLongitude);
  const startIdx = VIMSHOTTARI_ORDER.indexOf(nak.lord);
  const balance = (1 - nak.degree / (360 / 27)) * VIMSHOTTARI_YEARS[nak.lord];

  const dashas = [];
  let cur = new Date(birthDate);

  for (let cycle = 0; cycle < 2; cycle++) {
    for (let i = 0; i < 9; i++) {
      const li = (startIdx + i) % 9;
      const lord = VIMSHOTTARI_ORDER[li];
      let years = VIMSHOTTARI_YEARS[lord];
      if (cycle === 0 && i === 0) years = balance;

      const start = new Date(cur);
      const end = new Date(cur);
      end.setDate(end.getDate() + Math.round(years * 365.25));

      dashas.push({
        planet: lord, level: 'maha',
        start_date: start.toISOString().split('T')[0],
        end_date:   end.toISOString().split('T')[0],
        duration_years: years
      });

      // Antar dashas
      let aStart = new Date(start);
      for (let j = 0; j < 9; j++) {
        const ai = (li + j) % 9;
        const aLord = VIMSHOTTARI_ORDER[ai];
        const aYears = (years * VIMSHOTTARI_YEARS[aLord]) / 120;
        const aEnd = new Date(aStart);
        aEnd.setDate(aEnd.getDate() + Math.round(aYears * 365.25));
        dashas.push({
          planet: aLord, level: 'antar', parent_planet: lord,
          start_date: aStart.toISOString().split('T')[0],
          end_date:   aEnd.toISOString().split('T')[0],
          duration_years: aYears
        });
        aStart = new Date(aEnd);
      }
      cur = new Date(end);
    }
  }
  return dashas;
}

// ── Divisional Charts ────────────────────────────────────

function calculateDivisionalPosition(longitude, division) {
  const sd = longitude % 30;
  const bs = Math.floor(longitude / 30);
  switch (division) {
    case 1: return longitude;
    case 9: { // Navamsha
      const n = Math.floor(sd / (30/9));
      const ns = (bs * 9 + n) % 12;
      return ns * 30 + (sd % (30/9)) * 9;
    }
    default: {
      const part = Math.floor(sd / (30 / division));
      return ((bs * division + part) % 12) * 30 + (sd % (30/division)) * division;
    }
  }
}

// ── Yoga Detection ───────────────────────────────────────

function detectYogas(positions, cusps) {
  const yogas = [];
  const rashiOf = p => Math.floor(positions[p] / 30);
  const houseOf = p => getHouseNumber(positions[p], cusps);

  // Pancha Mahapurusha
  const pmP = ['mars','mercury','jupiter','venus','saturn'];
  const pmN = ['Ruchaka','Bhadra','Hamsa','Malavya','Shasha'];
  pmP.forEach((planet, i) => {
    const h = houseOf(planet);
    const d = getPlanetDignity(planet, positions[planet]);
    if ((d === 'exalted' || d === 'own') && [1,4,7,10].includes(h)) {
      yogas.push({ yoga_name: `${pmN[i]} Yoga`, yoga_type: 'pancha_mahapurusha',
        forming_planets: [planet], forming_houses: [h],
        strength: d === 'exalted' ? 1.0 : 0.8,
        description: `${pmN[i]} Yoga: ${planet} ${d} in kendra ${h}`,
        source_tradition: 'parashara', source_text: 'BPHS' });
    }
  });

  // Gajakesari
  const mh = houseOf('moon'), jh = houseOf('jupiter');
  if ([0,3,6,9].includes((jh - mh + 12) % 12)) {
    yogas.push({ yoga_name: 'Gajakesari Yoga', yoga_type: 'chandra',
      forming_planets: ['moon','jupiter'], forming_houses: [mh, jh],
      strength: 0.85, description: 'Moon-Jupiter in mutual kendras — wisdom and fame',
      source_tradition: 'parashara', source_text: 'Phaladipika' });
  }

  // Budhaditya
  if (rashiOf('sun') === rashiOf('mercury')) {
    yogas.push({ yoga_name: 'Budhaditya Yoga', yoga_type: 'solar',
      forming_planets: ['sun','mercury'], forming_houses: [houseOf('sun')],
      strength: 0.6, description: 'Sun-Mercury conjunction — intelligence & eloquence',
      source_tradition: 'classical_hora', source_text: 'Phaladipika' });
  }

  // Chandra-Mangala
  if (rashiOf('moon') === rashiOf('mars')) {
    yogas.push({ yoga_name: 'Chandra-Mangala Yoga', yoga_type: 'chandra',
      forming_planets: ['moon','mars'], forming_houses: [houseOf('moon')],
      strength: 0.6, description: 'Moon-Mars conjunction — wealth through enterprise',
      source_tradition: 'parashara' });
  }

  // Raja Yoga (kendra-trikona lord conjunction)
  const signLords = {};
  cusps.forEach((c, i) => { signLords[i+1] = RASHI_LORDS[Math.floor(c / 30)]; });
  [1,4,7,10].forEach(k => {
    [5,9].forEach(t => {
      const kl = signLords[k], tl = signLords[t];
      if (kl !== tl && houseOf(kl) === houseOf(tl)) {
        yogas.push({ yoga_name: `Raja Yoga (${k}L-${t}L)`, yoga_type: 'raja',
          forming_planets: [kl, tl], forming_houses: [k, t],
          strength: 0.75, description: `Lords of kendra ${k} and trikona ${t} conjoined`,
          source_tradition: 'parashara', source_text: 'BPHS' });
      }
    });
  });

  // Neecha Bhanga Raja Yoga
  PLANET_NAMES.forEach(planet => {
    if (getPlanetDignity(planet, positions[planet]) === 'debilitated') {
      const debSign = Math.floor(positions[planet] / 30);
      const debLord = RASHI_LORDS[debSign];
      const dld = getPlanetDignity(debLord, positions[debLord]);
      if (['exalted','own'].includes(dld) || houseOf(debLord) === 1) {
        yogas.push({ yoga_name: 'Neecha Bhanga Raja Yoga', yoga_type: 'neecha_bhanga',
          forming_planets: [planet, debLord], forming_houses: [houseOf(planet)],
          strength: 0.7, description: `Debilitated ${planet}'s sign lord ${debLord} cancels debility`,
          source_tradition: 'parashara', source_text: 'Phaladipika' });
      }
    }
  });

  // Parivartana Yoga
  for (let h1 = 1; h1 <= 12; h1++) {
    for (let h2 = h1+1; h2 <= 12; h2++) {
      const l1 = signLords[h1], l2 = signLords[h2];
      if (l1 !== l2 && houseOf(l1) === h2 && houseOf(l2) === h1) {
        yogas.push({ yoga_name: `Parivartana Yoga (${h1}-${h2})`, yoga_type: 'parivartana',
          forming_planets: [l1, l2], forming_houses: [h1, h2],
          strength: 0.7, description: `Mutual exchange of house lords ${h1} and ${h2}`,
          source_tradition: 'parashara', source_text: 'BPHS' });
      }
    }
  }

  return yogas;
}

// ── Main Entry Point ─────────────────────────────────────

function generateKundali(birthData) {
  const { date_of_birth, time_of_birth, latitude, longitude, timezone, ayanamsa = 'lahiri' } = birthData;
  const [year, month, day] = date_of_birth.split('-').map(Number);
  const [hour, minute, second = 0] = time_of_birth.split(':').map(Number);

  const localMoment = moment.tz(`${date_of_birth}T${time_of_birth}`, timezone);
  const utcOffset = localMoment.utcOffset() / 60;
  const utcHour = hour + minute / 60 + second / 3600 - utcOffset;

  const jd = dateToJulianDay(year, month, day, utcHour);
  const ayanamsaVal = calculateAyanamsa(jd, ayanamsa);
  const lst = localSiderealTime(jd, longitude);

  // Tropical → sidereal
  const tropical = calculatePlanetaryLongitudes(jd);
  const sidereal = {};
  for (const [p, lng] of Object.entries(tropical)) {
    sidereal[p] = ((lng - ayanamsaVal) % 360 + 360) % 360;
  }

  const ascTrop = calculateAscendant(lst, latitude);
  const ascendant = ((ascTrop - ayanamsaVal) % 360 + 360) % 360;
  sidereal.ascendant = ascendant;

  const cusps = calculateHouseCusps(ascendant);
  const ascRashi = getRashi(ascendant);
  const ascNak   = getNakshatra(ascendant);

  const allPlanets = ['sun','moon','mars','mercury','jupiter','venus','saturn','rahu','ketu'];
  const planetDetails = {};
  for (const planet of allPlanets) {
    const lng = sidereal[planet];
    const r = getRashi(lng), n = getNakshatra(lng);
    planetDetails[planet] = {
      planet, longitude: lng, rashi: r.name, rashi_degree: r.degree,
      nakshatra: n.name, nakshatra_pada: n.pada, nakshatra_lord: n.lord,
      house_number: getHouseNumber(lng, cusps),
      dignity: ['rahu','ketu'].includes(planet) ? 'neutral' : getPlanetDignity(planet, lng),
      is_retrograde: false
    };
  }

  const yogas = detectYogas(sidereal, cusps);
  const dashas = calculateVimshottariDasha(sidereal.moon, date_of_birth);

  // Divisional charts
  const divisions = [1,2,3,9,10,12];
  const divisionalCharts = {};
  for (const div of divisions) {
    divisionalCharts[`D${div}`] = {};
    for (const planet of allPlanets) {
      const dl = calculateDivisionalPosition(sidereal[planet], div);
      divisionalCharts[`D${div}`][planet] = { longitude: dl, rashi: getRashi(dl).name, rashi_degree: getRashi(dl).degree };
    }
  }

  const houses = cusps.map((c, i) => {
    const r = getRashi(c);
    return { house_number: i+1, cusp_longitude: c, rashi: r.name, lord: r.lord, sign_lord: r.lord, star_lord: getNakshatra(c).lord };
  });

  return {
    meta: { julian_day: jd, ayanamsa_used: ayanamsa, ayanamsa_value: ayanamsaVal, sidereal_time: lst, engine_version: '1.0.0' },
    ascendant: { longitude: ascendant, rashi: ascRashi.name, nakshatra: ascNak.name, nakshatra_pada: ascNak.pada },
    planets: planetDetails, houses, yogas, dashas, divisional_charts: divisionalCharts
  };
}

module.exports = {
  generateKundali, getRashi, getNakshatra, detectYogas, calculateVimshottariDasha,
  RASHIS, NAKSHATRAS, VIMSHOTTARI_ORDER, VIMSHOTTARI_YEARS
};
