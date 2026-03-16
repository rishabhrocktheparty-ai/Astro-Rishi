/**
 * Seed the Knowledge Graph with foundational Jyotish entities
 * Run: node scripts/seed-knowledge-graph.js
 */
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);

const GRAHAS = [
  { name: 'Sun', sanskrit_name: 'Surya / सूर्य', properties: { nature: 'malefic', gender: 'male', element: 'fire', caste: 'kshatriya', guna: 'sattvic', direction: 'east', gem: 'ruby', color: 'red', day: 'sunday', owns: ['Leo'], exalted_in: 'Aries 10°', debilitated_in: 'Libra 10°', moolatrikona: 'Leo 0-20°', karaka: ['soul','father','authority','government','health','vitality'], friends: ['Moon','Mars','Jupiter'], enemies: ['Venus','Saturn'], vimshottari_years: 6 }},
  { name: 'Moon', sanskrit_name: 'Chandra / चन्द्र', properties: { nature: 'benefic', gender: 'female', element: 'water', caste: 'vaishya', guna: 'sattvic', direction: 'northwest', gem: 'pearl', color: 'white', day: 'monday', owns: ['Cancer'], exalted_in: 'Taurus 3°', debilitated_in: 'Scorpio 3°', moolatrikona: 'Taurus 3-30°', karaka: ['mind','mother','emotions','public','liquids','travel'], friends: ['Sun','Mercury'], enemies: [], vimshottari_years: 10 }},
  { name: 'Mars', sanskrit_name: 'Mangala / मंगल', properties: { nature: 'malefic', gender: 'male', element: 'fire', caste: 'kshatriya', guna: 'tamasic', direction: 'south', gem: 'red coral', color: 'red', day: 'tuesday', owns: ['Aries','Scorpio'], exalted_in: 'Capricorn 28°', debilitated_in: 'Cancer 28°', moolatrikona: 'Aries 0-12°', karaka: ['energy','brothers','courage','land','surgery','military'], friends: ['Sun','Moon','Jupiter'], enemies: ['Mercury'], vimshottari_years: 7 }},
  { name: 'Mercury', sanskrit_name: 'Budha / बुध', properties: { nature: 'neutral', gender: 'neuter', element: 'earth', caste: 'vaishya', guna: 'rajasic', direction: 'north', gem: 'emerald', color: 'green', day: 'wednesday', owns: ['Gemini','Virgo'], exalted_in: 'Virgo 15°', debilitated_in: 'Pisces 15°', moolatrikona: 'Virgo 15-20°', karaka: ['intellect','speech','commerce','writing','mathematics','friends'], friends: ['Sun','Venus'], enemies: ['Moon'], vimshottari_years: 17 }},
  { name: 'Jupiter', sanskrit_name: 'Guru / गुरु', properties: { nature: 'benefic', gender: 'male', element: 'ether', caste: 'brahmin', guna: 'sattvic', direction: 'northeast', gem: 'yellow sapphire', color: 'yellow', day: 'thursday', owns: ['Sagittarius','Pisces'], exalted_in: 'Cancer 5°', debilitated_in: 'Capricorn 5°', moolatrikona: 'Sagittarius 0-10°', karaka: ['wisdom','children','dharma','wealth','guru','husband'], friends: ['Sun','Moon','Mars'], enemies: ['Mercury','Venus'], vimshottari_years: 16 }},
  { name: 'Venus', sanskrit_name: 'Shukra / शुक्र', properties: { nature: 'benefic', gender: 'female', element: 'water', caste: 'brahmin', guna: 'rajasic', direction: 'southeast', gem: 'diamond', color: 'white', day: 'friday', owns: ['Taurus','Libra'], exalted_in: 'Pisces 27°', debilitated_in: 'Virgo 27°', moolatrikona: 'Libra 0-15°', karaka: ['love','marriage','art','luxury','vehicles','wife','beauty'], friends: ['Mercury','Saturn'], enemies: ['Sun','Moon'], vimshottari_years: 20 }},
  { name: 'Saturn', sanskrit_name: 'Shani / शनि', properties: { nature: 'malefic', gender: 'neuter', element: 'air', caste: 'shudra', guna: 'tamasic', direction: 'west', gem: 'blue sapphire', color: 'blue/black', day: 'saturday', owns: ['Capricorn','Aquarius'], exalted_in: 'Libra 20°', debilitated_in: 'Aries 20°', moolatrikona: 'Aquarius 0-20°', karaka: ['longevity','karma','discipline','servants','sorrow','delays','iron'], friends: ['Mercury','Venus'], enemies: ['Sun','Moon','Mars'], vimshottari_years: 19 }},
  { name: 'Rahu', sanskrit_name: 'Rahu / राहु', properties: { nature: 'malefic', gender: 'neuter', element: 'air', guna: 'tamasic', gem: 'hessonite', karaka: ['foreign','illusion','technology','obsession','paternal grandfather'], vimshottari_years: 18 }},
  { name: 'Ketu', sanskrit_name: 'Ketu / केतु', properties: { nature: 'malefic', gender: 'neuter', element: 'fire', guna: 'tamasic', gem: 'cats eye', karaka: ['moksha','spirituality','detachment','maternal grandfather','occult'], vimshottari_years: 7 }}
];

const RASHIS = [
  { name: 'Aries', sanskrit_name: 'Mesha / मेष', properties: { element: 'fire', quality: 'movable', gender: 'male', lord: 'Mars', exalted_planet: 'Sun', debilitated_planet: 'Saturn', body_part: 'head' }},
  { name: 'Taurus', sanskrit_name: 'Vrishabha / वृषभ', properties: { element: 'earth', quality: 'fixed', gender: 'female', lord: 'Venus', exalted_planet: 'Moon', debilitated_planet: 'none', body_part: 'face/throat' }},
  { name: 'Gemini', sanskrit_name: 'Mithuna / मिथुन', properties: { element: 'air', quality: 'dual', gender: 'male', lord: 'Mercury', body_part: 'arms/shoulders' }},
  { name: 'Cancer', sanskrit_name: 'Karka / कर्क', properties: { element: 'water', quality: 'movable', gender: 'female', lord: 'Moon', exalted_planet: 'Jupiter', debilitated_planet: 'Mars', body_part: 'chest' }},
  { name: 'Leo', sanskrit_name: 'Simha / सिंह', properties: { element: 'fire', quality: 'fixed', gender: 'male', lord: 'Sun', body_part: 'stomach' }},
  { name: 'Virgo', sanskrit_name: 'Kanya / कन्या', properties: { element: 'earth', quality: 'dual', gender: 'female', lord: 'Mercury', exalted_planet: 'Mercury', debilitated_planet: 'Venus', body_part: 'waist' }},
  { name: 'Libra', sanskrit_name: 'Tula / तुला', properties: { element: 'air', quality: 'movable', gender: 'male', lord: 'Venus', exalted_planet: 'Saturn', debilitated_planet: 'Sun', body_part: 'lower abdomen' }},
  { name: 'Scorpio', sanskrit_name: 'Vrishchika / वृश्चिक', properties: { element: 'water', quality: 'fixed', gender: 'female', lord: 'Mars', debilitated_planet: 'Moon', body_part: 'genitals' }},
  { name: 'Sagittarius', sanskrit_name: 'Dhanu / धनु', properties: { element: 'fire', quality: 'dual', gender: 'male', lord: 'Jupiter', body_part: 'thighs' }},
  { name: 'Capricorn', sanskrit_name: 'Makara / मकर', properties: { element: 'earth', quality: 'movable', gender: 'female', lord: 'Saturn', exalted_planet: 'Mars', debilitated_planet: 'Jupiter', body_part: 'knees' }},
  { name: 'Aquarius', sanskrit_name: 'Kumbha / कुम्भ', properties: { element: 'air', quality: 'fixed', gender: 'male', lord: 'Saturn', body_part: 'calves' }},
  { name: 'Pisces', sanskrit_name: 'Meena / मीन', properties: { element: 'water', quality: 'dual', gender: 'female', lord: 'Jupiter', exalted_planet: 'Venus', debilitated_planet: 'Mercury', body_part: 'feet' }}
];

const BHAVAS = [
  { name: '1st House (Tanu Bhava)', properties: { significations: ['self','body','appearance','personality','health','fame','beginning'], natural_sign: 'Aries' }},
  { name: '2nd House (Dhana Bhava)', properties: { significations: ['wealth','family','speech','food','right eye','face','values'], natural_sign: 'Taurus' }},
  { name: '3rd House (Sahaja Bhava)', properties: { significations: ['siblings','courage','communication','short travel','arts','hands'], natural_sign: 'Gemini' }},
  { name: '4th House (Sukha Bhava)', properties: { significations: ['mother','home','education','happiness','vehicles','land','heart'], natural_sign: 'Cancer' }},
  { name: '5th House (Putra Bhava)', properties: { significations: ['children','intelligence','creativity','romance','past merit','mantras'], natural_sign: 'Leo' }},
  { name: '6th House (Ari Bhava)', properties: { significations: ['enemies','disease','debts','service','obstacles','maternal uncle'], natural_sign: 'Virgo' }},
  { name: '7th House (Yuvati Bhava)', properties: { significations: ['spouse','marriage','partnership','business','foreign travel','death'], natural_sign: 'Libra' }},
  { name: '8th House (Randhra Bhava)', properties: { significations: ['death','longevity','transformation','occult','inheritance','chronic illness'], natural_sign: 'Scorpio' }},
  { name: '9th House (Dharma Bhava)', properties: { significations: ['father','dharma','fortune','guru','pilgrimage','higher learning','philosophy'], natural_sign: 'Sagittarius' }},
  { name: '10th House (Karma Bhava)', properties: { significations: ['career','status','authority','government','fame','public life','knees'], natural_sign: 'Capricorn' }},
  { name: '11th House (Labha Bhava)', properties: { significations: ['gains','income','friends','elder siblings','hopes','wishes','networks'], natural_sign: 'Aquarius' }},
  { name: '12th House (Vyaya Bhava)', properties: { significations: ['loss','expenditure','moksha','foreign lands','isolation','bed pleasures','left eye'], natural_sign: 'Pisces' }}
];

async function seed() {
  console.log('Seeding knowledge graph...');

  // Insert graha nodes
  for (const g of GRAHAS) {
    const { error } = await db.from('kg_nodes').upsert({
      node_type: 'graha', name: g.name, sanskrit_name: g.sanskrit_name, properties: g.properties
    }, { onConflict: 'name' });
    if (error) console.error(`Graha ${g.name}:`, error.message);
  }
  console.log(`  ✓ ${GRAHAS.length} grahas`);

  // Insert rashi nodes
  for (const r of RASHIS) {
    const { error } = await db.from('kg_nodes').upsert({
      node_type: 'rashi', name: r.name, sanskrit_name: r.sanskrit_name, properties: r.properties
    }, { onConflict: 'name' });
    if (error) console.error(`Rashi ${r.name}:`, error.message);
  }
  console.log(`  ✓ ${RASHIS.length} rashis`);

  // Insert bhava nodes
  for (const b of BHAVAS) {
    const { error } = await db.from('kg_nodes').upsert({
      node_type: 'bhava', name: b.name, properties: b.properties
    }, { onConflict: 'name' });
    if (error) console.error(`Bhava ${b.name}:`, error.message);
  }
  console.log(`  ✓ ${BHAVAS.length} bhavas`);

  // Create edges: planet owns rashi
  const ownership = { Sun: ['Leo'], Moon: ['Cancer'], Mars: ['Aries','Scorpio'], Mercury: ['Gemini','Virgo'], Jupiter: ['Sagittarius','Pisces'], Venus: ['Taurus','Libra'], Saturn: ['Capricorn','Aquarius'] };
  let edgeCount = 0;
  for (const [planet, signs] of Object.entries(ownership)) {
    const { data: pNode } = await db.from('kg_nodes').select('id').eq('name', planet).eq('node_type', 'graha').single();
    for (const sign of signs) {
      const { data: sNode } = await db.from('kg_nodes').select('id').eq('name', sign).eq('node_type', 'rashi').single();
      if (pNode && sNode) {
        await db.from('kg_edges').upsert({ source_node_id: pNode.id, target_node_id: sNode.id, relationship: 'owns' });
        edgeCount++;
      }
    }
  }

  // Create edges: planet exalted_in / debilitated_in
  const exaltMap = { Sun: 'Aries', Moon: 'Taurus', Mars: 'Capricorn', Mercury: 'Virgo', Jupiter: 'Cancer', Venus: 'Pisces', Saturn: 'Libra' };
  const debilMap = { Sun: 'Libra', Moon: 'Scorpio', Mars: 'Cancer', Mercury: 'Pisces', Jupiter: 'Capricorn', Venus: 'Virgo', Saturn: 'Aries' };
  for (const [planet, sign] of Object.entries(exaltMap)) {
    const { data: pNode } = await db.from('kg_nodes').select('id').eq('name', planet).eq('node_type', 'graha').single();
    const { data: sNode } = await db.from('kg_nodes').select('id').eq('name', sign).eq('node_type', 'rashi').single();
    if (pNode && sNode) { await db.from('kg_edges').insert({ source_node_id: pNode.id, target_node_id: sNode.id, relationship: 'exalted_in' }); edgeCount++; }
  }
  for (const [planet, sign] of Object.entries(debilMap)) {
    const { data: pNode } = await db.from('kg_nodes').select('id').eq('name', planet).eq('node_type', 'graha').single();
    const { data: sNode } = await db.from('kg_nodes').select('id').eq('name', sign).eq('node_type', 'rashi').single();
    if (pNode && sNode) { await db.from('kg_edges').insert({ source_node_id: pNode.id, target_node_id: sNode.id, relationship: 'debilitated_in' }); edgeCount++; }
  }

  // Friendships
  const friends = { Sun: ['Moon','Mars','Jupiter'], Moon: ['Sun','Mercury'], Mars: ['Sun','Moon','Jupiter'], Mercury: ['Sun','Venus'], Jupiter: ['Sun','Moon','Mars'], Venus: ['Mercury','Saturn'], Saturn: ['Mercury','Venus'] };
  for (const [p, fList] of Object.entries(friends)) {
    const { data: pNode } = await db.from('kg_nodes').select('id').eq('name', p).eq('node_type', 'graha').single();
    for (const f of fList) {
      const { data: fNode } = await db.from('kg_nodes').select('id').eq('name', f).eq('node_type', 'graha').single();
      if (pNode && fNode) { await db.from('kg_edges').insert({ source_node_id: pNode.id, target_node_id: fNode.id, relationship: 'friends_with' }); edgeCount++; }
    }
  }

  const enemies = { Sun: ['Venus','Saturn'], Mars: ['Mercury'], Mercury: ['Moon'], Jupiter: ['Mercury','Venus'], Venus: ['Sun','Moon'], Saturn: ['Sun','Moon','Mars'] };
  for (const [p, eList] of Object.entries(enemies)) {
    const { data: pNode } = await db.from('kg_nodes').select('id').eq('name', p).eq('node_type', 'graha').single();
    for (const e of eList) {
      const { data: eNode } = await db.from('kg_nodes').select('id').eq('name', e).eq('node_type', 'graha').single();
      if (pNode && eNode) { await db.from('kg_edges').insert({ source_node_id: pNode.id, target_node_id: eNode.id, relationship: 'enemies_with' }); edgeCount++; }
    }
  }

  console.log(`  ✓ ${edgeCount} edges created`);
  console.log('Knowledge graph seeding complete!');
}

seed().catch(console.error);
