/** @file tony.y
 * Tony programming language parser.
 * Based on http://idlebox.net/2007/flex-bison-cpp-example/
 *
 * Licensed under the GPLv3.
 */

%% /*** Grammar Rules ***/

%% /*** Additional Code ***/

void tony::Parser::error(const Parser::location_type& l,
                const std::string& m)
{
    driver.error(l, m);
}
