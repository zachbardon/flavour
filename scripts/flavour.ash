script "Auto-Flavour";
notify "Soolar the Second";

import <zlib.ash>;

float EPSILON = 0.00001;

boolean float_equals(float f1, float f2)
{
	return abs(f1 - f2) < EPSILON;
}

void flavour_auto_tune()
{
	setvar("flavour.perfectonly", false);
	setvar("flavour.disabled", false);
	
	location loc = my_location();
	
	if(to_boolean(vars["flavour.disabled"]))
		return;
	if(!have_skill($skill[Flavour of Magic]) || !be_good($skill[Flavour of Magic]))
		return;
	if(loc == $location[Hobopolis Town Square]) // Don't interfere with Scarehobos
		return;
	
	float [element] double_damage;
	boolean [element] perfect;
	float [element] one_damage;
	
	foreach ele in $elements[cold, hot, sleaze, spooky, stench, none]
	{
		double_damage[ele] = 0;
		one_damage[ele] = 0;
		perfect[ele] = true;
	}
	
	boolean [element] weak_elements(element ele)
	{
		switch(ele)
		{
			case $element[cold]: return $elements[hot, spooky];
			case $element[spooky]: return $elements[hot, stench];
			case $element[hot]: return $elements[stench, sleaze];
			case $element[stench]: return $elements[sleaze, cold];
			case $element[sleaze]: return $elements[cold, spooky];
			default: return $elements[none];
		}
	}
	
	void handle_monster(monster mon, float chance)
	{
		if(chance == 0 || mon == $monster[none])
			return;
		
		boolean [element] weaknesses = weak_elements(mon.defense_element);
		
		foreach ele in $elements[cold, hot, sleaze, spooky, stench]
		{
			if(ele == mon.defense_element)
				one_damage[ele] += chance;
			
			if(weaknesses contains ele)
				double_damage[ele] += chance;
			else
				perfect[ele] = false;
		}
	}
	
	foreach mon,chance in appearance_rates(loc, true)
		handle_monster(mon, chance);
	
	// Effectively never tune to cold in OCRS because of cold monsters
	if(my_path() == "One Crazy Random Summer")
		one_damage[$element[cold]] += 1;
	
	element flavour = $element[none];
	float best_score = -1;
	float best_spell_damage = -99999;
	
	foreach ele in $elements[cold, hot, sleaze, spooky, stench]
	{
		float spell_damage = numeric_modifier(ele.to_string() + " Spell Damage");
		if(one_damage[ele] == 0 && ((double_damage[ele] > best_score) || (float_equals(double_damage[ele], best_score) && (spell_damage > best_spell_damage))))
		{
			flavour = ele;
			best_score = double_damage[ele];
			best_spell_damage = spell_damage;
		}
	}
	
	if(to_boolean(vars["flavour.perfectonly"]) && !perfect[flavour])
		flavour = $element[none];
	
	item offhand = equipped_item($slot[off-hand]);
	
	switch(loc)
	{
		case $location[The Ancient Hobo Burial Ground]: // Everything here is immune to elemental dmg
			flavour = $element[none];
			break;
		case $location[The Ice Hotel]:
			if(get_property("walfordBucketItem") == "rain" && offhand == $item[Walford's bucket])
				flavour = $element[hot]; // Doing 100 hot damage in a fight will fill the bucket faster
			// Lack of break is intentional
		case $location[VYKEA]:
			if(get_property("walfordBucketItem") == "ice" && offhand == $item[Walford's bucket])
				flavour = $element[cold]; // It will do 1 damage unless you change their element somehow, but doing 10 cold damage speeds filling the bucket
			break;
	}
	
	element current_flavour = $element[none];
	if(have_effect($effect[Spirit of Bacon Grease]) > 0)
		current_flavour = $element[sleaze];
	else if(have_effect($effect[Spirit of Garlic]) > 0)
		current_flavour = $element[stench];
	else if(have_effect($effect[Spirit of Cayenne]) > 0)
		current_flavour = $element[hot];
	else if(have_effect($effect[Spirit of Wormwood]) > 0)
		current_flavour = $element[spooky];
	else if(have_effect($effect[Spirit of Peppermint]) > 0)
		current_flavour = $element[cold];
	
	if(flavour != current_flavour)
	{
		switch(flavour)
		{
			case $element[none]:
				use_skill(1, $skill[Spirit of Nothing]);
				break;
			case $element[hot]:
				use_skill(1, $skill[Spirit of Cayenne]);
				break;
			case $element[cold]:
				use_skill(1, $skill[Spirit of Peppermint]);
				break;
			case $element[stench]:
				use_skill(1, $skill[Spirit of Garlic]);
				break;
			case $element[spooky]:
				use_skill(1, $skill[Spirit of Wormwood]);
				break;
			case $element[sleaze]:
				use_skill(1, $skill[Spirit of Bacon Grease]);
				break;
		}
	}
}

void main()
{
	flavour_auto_tune();
}
