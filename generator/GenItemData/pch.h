// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file

#ifndef PCH_H
#define PCH_H

// TODO: add headers that you want to pre-compile here

// Yeah, so relative pathing (pretty bad). Big @todo to move to an environment variable or something.
// But, if you're looking at this before that happens, this assumes the following directory structure:
//
// [Top Level] > [simc] (github)
// [Top Level] > Better Tooltips > generator

#include <vector>
#include <string>

#include "..\..\..\simc\engine\dbc\dbc.hpp"
#include "..\..\..\simc\engine\dbc\generated\sc_item_data.inc"
#include "..\..\..\simc\engine\dbc\generated\azerite.inc"
#include "..\..\..\simc\engine\dbc\generated\sc_spell_data.inc"
#include "..\..\..\simc\engine\dbc\generated\sc_item_data2.inc"


static std::vector< item_enchantment_data_t> enchantsData{ std::begin(__spell_item_ench_data), std::end(__spell_item_ench_data) };
static std::vector<spell_data_t> spellData{ std::begin(__spell_data), std::end(__spell_data) };
static std::vector<spelleffect_data_t> sed{ std::begin(__spelleffect_data), std::end(__spelleffect_data) };
static std::vector< item_data_t> itemData{ std::begin(__item_data), std::end(__item_data) };
static std::vector< azerite_power_entry_t > azeritePowers{ std::begin(__azerite_power_data), std::end(__azerite_power_data) };


#endif //PCH_H
