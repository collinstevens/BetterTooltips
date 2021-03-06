// GenItemData.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include "pch.h"
#include <iostream>
#include <vector>
#include <algorithm>



#include <vector>
#include <iostream>
#include <fstream>
#include <iosfwd>
#include <ostream>

//************************************
// Method:    ReplaceAll
// FullName:  ReplaceAll
// Access:    public 
// Returns:   std::string
// Qualifier:
// Parameter: std::string str - String being replaced
// Parameter: const std::string & from - Substring to replace
// Parameter: const std::string & to - Substring to replace with
// 
// Replaces substrings within a string.
//************************************
std::string ReplaceAll(std::string str, const std::string& from, const std::string& to) {
	size_t start_pos = 0;
	while ((start_pos = str.find(from, start_pos)) != std::string::npos) {
		str.replace(start_pos, from.length(), to);
		start_pos += to.length(); // Handles case where 'to' is a substring of 'from'
	}

	return str;
}

static int num_tabs = 0;

std::string tabs()
{
	std::string rc;
	for (int index = 0; index < num_tabs; index++)
	{
		rc += "\t";
	}

	return rc;
}

// Small raii tab class for the global tabs count
class indented_section
{
public:
	indented_section() { num_tabs++; }
	~indented_section() { num_tabs--; }
};

int main()
{
	std::ofstream outs("..\\..\\addon\\Data.lua", std::ios::out);

	outs << "E_CHANCE = 1" << std::endl;
	outs << "E_RPPM = 2" << std::endl;
	outs << "E_NAME = 3" << std::endl;
	outs << "E_ICD = 4" << std::endl;
	outs << "E_AZERITE_POWER = 5" << std::endl;
	outs << "E_SPELLID = 6" << std::endl;
    outs << "E_DESC = 7" << std::endl;
    outs << "E_REFID = 8" << std::endl;
	outs << "AdvancedTooltips.Items = {" << std::endl;
	indented_section itemssection;
	for (auto&& id : itemData)
	{
		bool header = false;
		// Get the spell reference, if there is one
		for (int Index = 0; Index < MAX_ITEM_EFFECT; Index++)
		{

			if (id.trigger_spell[Index] != 0)
			{
				auto spell = std::find_if(spellData.begin(), spellData.end(), [&](auto&& sd)
				{
					return sd._id == id.id_spell[Index];
				});

				if (spell == spellData.end())
					continue;

				if (spell->_rppm == 0 && spell->_proc_chance == 0)
					continue;




				double procChance = spell->_rppm != 0 ? spell->_rppm : spell->_proc_chance;
				if (procChance >= 100)
					continue;

				if (!header)
				{
					outs << tabs() << "[" << id.id << "] = {" << std::endl;
					header = true;
				}

				indented_section item;
				bool isRPPM = spell->_rppm != 0;
				outs << tabs() << "[" << Index + 1 << "] = {" << std::endl;
				{
					indented_section itemData;
					outs << tabs() << "[E_CHANCE] = " << procChance << "," << std::endl;
					outs << tabs() << "[E_RPPM] = " << isRPPM << "," << std::endl;
					std::string Description = ReplaceAll(std::string(spell->_name), std::string("'"), std::string("\\'"));
					Description = ReplaceAll(Description, std::string("\""), std::string("\\\""));
					outs << tabs() << "[E_NAME] = " << "\"" << Description << "\"" << "," << std::endl;
					outs << tabs() << "[E_ICD] = " << spell->_internal_cooldown << "," << std::endl;
					outs << tabs() << "[E_SPELLID] = " << spell->_id << "," << std::endl;
				}
				outs << tabs() << "}," << std::endl;
			}
		}

		if (header)
			outs << tabs() << "}," << std::endl;
	}

	outs << "}" << std::endl;

	outs << std::endl;

	outs << "AdvancedTooltips.SpellData = {" << std::endl;

	indented_section spell_data_section;

	bool Header = false;

	for (auto&& sd : spellData)
	{
		if (Header)
		{
			// We continued from the previous loop. close the existing header item
			indented_section close;
			outs << "},";
			Header = false;
		}

		// Check if the spell data has an associated spell effect.
		auto refSpell = std::find_if(sed.begin(), sed.end(), [&](auto&& data)
		{
			return data._spell_id == sd._id;
		});

		// refSpell->_id is the actual spell

		// Grab the associated actual spell
		auto actualSpell = std::find_if(spellData.begin(), spellData.end(), [&](auto&& spd)
		{
			return refSpell->_trigger_spell_id == spd._id;
		});




		indented_section spell_data;

		if (!Header)
		{
			outs << tabs() << "[" << sd._id << "] = {" << std::endl;
			Header = true;
		}


		{
			indented_section data;
			if (actualSpell != spellData.end())
			{
				if (actualSpell->_internal_cooldown != 0)
				{

					outs << tabs() << "[E_ICD] = " << actualSpell->_internal_cooldown << "," << std::endl;
				}

				// Some things in simc are modeled as procs with 100% chance to proc, skip over those
				if (actualSpell->_proc_chance == 101 && actualSpell->_rppm == 0 && sd._rppm == 0)
					continue;

				if ((actualSpell->_proc_chance != 0 && actualSpell->_proc_chance < 100) || actualSpell->_rppm != 0)
				{


					bool isRPPM = actualSpell->_rppm != 0;
					outs << tabs() << "[E_RPPM] = " << isRPPM << "," << std::endl;
					double procChance = actualSpell->_rppm != 0 ? actualSpell->_rppm : actualSpell->_proc_chance;
					outs << tabs() << "[E_CHANCE] = " << procChance << "," << std::endl;
				}
				else if (sd._rppm != 0 || sd._proc_chance != 0)
				{
					bool isRPPM = sd._rppm != 0;
					outs << tabs() << "[E_RPPM] = " << isRPPM << "," << std::endl;
					double procChance = sd._rppm != 0 ? sd._rppm : sd._proc_chance;
					outs << tabs() << "[E_CHANCE] = " << procChance << "," << std::endl;
				}

			}
			else
			{
				if (sd._internal_cooldown != 0)
				{
					outs << tabs() << "[E_ICD] = " << sd._internal_cooldown << "," << std::endl;
				}

				if (sd._proc_chance == 101 && sd._rppm == 0)
					continue;

				if (sd._proc_chance != 0 || sd._rppm != 0)
				{
					bool isRPPM = sd._rppm != 0;
					outs << tabs() << "[E_RPPM] = " << isRPPM << "," << std::endl;
					double procChance = sd._rppm != 0 ? sd._rppm : sd._proc_chance;
					outs << tabs() << "[E_CHANCE] = " << procChance << "," << std::endl;

				}
			}

			// If this is an azerite power, map its ID.
			auto power = std::find_if(azeritePowers.begin(), azeritePowers.end(), [&](auto&& power)
			{
                // Hack for Bonded Souls

                if (sd._id == 288804)
                {
                    return power.spell_id == 288802;
                }

				return power.spell_id == sd._id;
			});



			if (power != azeritePowers.end())
			{
				// Ok, write this info
				outs << tabs() << "[E_AZERITE_POWER] = " << power->id << "," << std::endl;
			}
		}

		if (Header)
		{
			outs << tabs() << "}," << std::endl;
			Header = false;
		}
	}

	outs << "}" << std::endl;
	outs << std::endl;

	outs << "AdvancedTooltips.EnchantData = {" << std::endl;

	for (auto&& ie : enchantsData)
	{
		if (ie.id_spell == 0)
			continue;

		outs << tabs() << "[" << ie.id << "] = " << ie.ench_prop[0] << "," << std::endl;
		outs << tabs() << "[" << ie.id_spell << "] = " << ie.ench_prop[0] << "," << std::endl;
	}

	outs << "}";

}