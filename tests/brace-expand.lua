-- Test brace-expand.lua (not a real test unit, just a regular script)


brace_expand = require 'brace-expand'

local tests = {
    { "" ; "" },
    { "1" ; "1" },
    { "1 {a} 2" ; "1 {a} 2" },
    { "1 {,a,b,} 2" ; "1  2", "1 a 2", "1 b 2", "1  2" },
    { "1 {a,b} 2" ; "1 a 2", "1 b 2" },
    { "1 {a,b} 2 {c,d} 3" ; "1 a 2 c 3", "1 a 2 d 3", "1 b 2 c 3", "1 b 2 d 3" },
    { "1 \\{2, 3\\} 4" ; "1 \\{2, 3\\} 4" },
    { "1 {a\\,a,b\\,b} 2" ; "1 a\\,a 2", "1 b\\,b 2" },
    { "1 {a,{f,g},z} 2" ; "1 a 2", "1 f 2", "1 g 2", "1 z 2" },
    { "1 {a,b{f,g}c,z} 2" ; "1 a 2", "1 bfc 2", "1 bgc 2", "1 z 2" },
    { "a {3..9..2} b" ; "a 3 b", "a 5 b", "a 7 b", "a 9 b" },
    { "a {-3..-9..-2} b" ; "a -3 b", "a -5 b", "a -7 b", "a -9 b" },
    { "a {3..9..-2} b" ; "a 3 b", "a 5 b", "a 7 b", "a 9 b" },
    { "a {-3..-9..2} b" ; "a -3 b", "a -5 b", "a -7 b", "a -9 b" },
    { "a {4..7} b" ; "a 4 b", "a 5 b", "a 6 b", "a 7 b" },
    { "a {2..-2} b" ; "a 2 b", "a 1 b", "a 0 b", "a -1 b", "a -2 b" },
    { "a {-2..2} b" ; "a -2 b", "a -1 b", "a 0 b", "a 1 b", "a 2 b" },
    { "a {9..11..1} b" ; "a 9 b", "a 10 b", "a 11 b" },
    { "a {09..11..1} b" ; "a 09 b", "a 10 b", "a 11 b" },
    { "a {9..011..1} b" ; "a 009 b", "a 010 b", "a 011 b" },
    { "a {9..0011..1} b" ; "a 0009 b", "a 0010 b", "a 0011 b" },
    { "a {09..11} b" ; "a 09 b", "a 10 b", "a 11 b" },
    { "a {9..011} b" ; "a 009 b", "a 010 b", "a 011 b" },
    { "a {9..0011} b" ; "a 0009 b", "a 0010 b", "a 0011 b" },
    { "a {-2..02} b" ; "a -2 b", "a -1 b", "a 00 b", "a 01 b", "a 02 b" },
    { "a {-02..2} b" ; "a -02 b", "a -01 b", "a 000 b", "a 001 b", "a 002 b" },
    { "1 {a..j..3} 2" ; "1 a 2", "1 d 2", "1 g 2", "1 j 2" },
    { "1 {a..h..3} 2" ; "1 a 2", "1 d 2", "1 g 2" },
    { "1 {A..E..1} 2" ; "1 A 2", "1 B 2", "1 C 2", "1 D 2", "1 E 2" },
    { "1 {a..d} 2" ; "1 a 2", "1 b 2", "1 c 2", "1 d 2" },
    { "1 {A..C} 2" ; "1 A 2", "1 B 2", "1 C 2", },
    { "1 {d..a} 2" ; "1 d 2", "1 c 2", "1 b 2", "1 a 2" },
    { "1 {C..A} 2" ; "1 C 2", "1 B 2", "1 A 2" },
    { "a {1} b" ; "a {1} b" },
    { "a {1..1} b" ; "a 1 b" },
    { "{}" ; "{}" },
    { "a {} b" ; "a {} b" },
    { "a {} b {1,2} c" ; "a {} b 1 c", "a {} b 2 c" },

    -- Corner cases
    { '{1},2}' ; '1}', '2' },
    { '{1}2},3}' ; '1}2}', '3' },
    { '{1}2}3},4}' ; '1}2}3}', '4' },
    { '{}1,2}' ; '{}1,2}' },

    -- Documentation example
    { "{1!,a } {-2..08..5} {z..x}" ; 
            "1! -2 z",   "1! -2 y",   "1! -2 x",
            "1! 03 z",   "1! 03 y",   "1! 03 x",
            "1! 08 z",   "1! 08 y",   "1! 08 x",

            "a  -2 z",   "a  -2 y",   "a  -2 x",
            "a  03 z",   "a  03 y",   "a  03 x",
            "a  08 z",   "a  08 y",   "a  08 x",
    },

    -- Taken from the bash source (tests/braces.tests)
    { "ff{c,b,a}" ; "ffc", "ffb", "ffa" },
    { "f{d,e,f}g" ; "fdg", "feg", "ffg" },
    { "{l,n,m}xyz" ; "lxyz", "nxyz", "mxyz" },
    { "{abc\\,def}" ; "{abc\\,def}" },
    { "{abc}" ; "{abc}" },

    { "\\{a,b,c,d,e}" ; "\\{a,b,c,d,e}" },
    { "{x,y,\\{a,b,c}}" ; "x}", "y}", "\\{a}", "b}", "c}" },
    { "{x\\,y,\\{abc\\},trie}" ; "x\\,y", "\\{abc\\}", "trie" },

    { "/usr/{ucb/{ex,edit},lib/{ex,how_ex}}" ;
        "/usr/ucb/ex", "/usr/ucb/edit", "/usr/lib/ex", "/usr/lib/how_ex" },

    { "{}" ; "{}" },
    { "{ }" ; "{ }" },
    { "}" ; "}" },
    { "{" ; "{" },
    { "abcd{efgh" ; "abcd{efgh" },

    { "foo {1,2} bar" ; "foo 1 bar", "foo 2 bar" },

    { "{1..10}" ;
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },

    { "{0..10,braces}" ; "0..10", "braces" },
    { "{{0..10},braces}" ;
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "braces" },
    { "x{{0..10},braces}y" ;
        "x0y", "x1y", "x2y", "x3y", "x4y", "x5y", "x6y", "x7y", "x8y", "x9y", "x10y", "xbracesy" },

    { "{3..3}" ; "3" },
    { "x{3..3}y" ; "x3y" },
    { "{10..1}" ;
        "10", "9", "8", "7", "6", "5", "4", "3", "2", "1" },
    { "{10..1}y" ;
        "10y", "9y", "8y", "7y", "6y", "5y", "4y", "3y", "2y", "1y" },
    { "x{10..1}y" ;
        "x10y", "x9y", "x8y", "x7y", "x6y", "x5y", "x4y", "x3y", "x2y", "x1y" },

    { "{a..f}" ; "a", "b", "c", "d", "e", "f" },
    { "{f..a}" ; "f", "e", "d", "c", "b", "a" },

    { "{a..A}" ;
        "a", "`", "_", "^", "]", "\\", "[", "Z", "Y", "X", "W", "V", "U", "T", "S", "R", "Q", "P", "O", "N", "M", "L", "K", "J", "I", "H", "G", "F", "E", "D", "C", "B", "A" },
    { "{A..a}" ;
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_", "`", "a" },

    { "{f..f}" ; "f" },

    -- # mixes are incorrectly-formed brace expansions
    { "{1..f}" ; "{1..f}" },
    { "{f..1}" ; "{f..1}" },

    { "0{1..4} {10..11}" ;
        "01 10", "01 11", "02 10", "02 11", "03 10", "03 11", "04 10", "04 11" },

    -- # do negative numbers work?
    { "{-1..-10}" ;
        "-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9", "-10" },
    { "{-20..0}" ;
        "-20", "-19", "-18", "-17", "-16", "-15", "-14", "-13", "-12", "-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "0" },

    -- # weirdly-formed brace expansions -- fixed in post-bash-3.1
    { "a-{b{d,e}}-c" ; "a-{bd}-c", "a-{be}-c" },

    { "a-{bdef-{g,i}-c" ; "a-{bdef-g-c", "a-{bdef-i-c" },

    { "{klklkl}{1,2,3}" ; "{klklkl}1", "{klklkl}2", "{klklkl}3" },
    { "{x\\,x}" ; "{x\\,x}" },

    { "{1..10..2}" ; "1", "3", "5", "7", "9" },
    { "{-1..-10..2}" ; "-1", "-3", "-5", "-7", "-9" },
    { "{-1..-10..-2}" ; "-1", "-3", "-5", "-7", "-9" },

    { "{10..1..-2}" ; "10", "8", "6", "4", "2" },
    { "{10..1..2}" ; "10", "8", "6", "4", "2" },

    { "{1..20..2}" ; "1", "3", "5", "7", "9", "11", "13", "15", "17", "19" },
    { "{1..20..20}" ; "1" },

    { "{100..0..5}" ;
        "100", "95", "90", "85", "80", "75", "70", "65", "60", "55", "50", "45", "40", "35", "30", "25", "20", "15", "10", "5", "0" },
    { "{100..0..-5}" ;
        "100", "95", "90", "85", "80", "75", "70", "65", "60", "55", "50", "45", "40", "35", "30", "25", "20", "15", "10", "5", "0" },

    { "{a..z}" ;
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" },
    { "{a..z..2}" ;
        "a", "c", "e", "g", "i", "k", "m", "o", "q", "s", "u", "w", "y" },
    { "{z..a..-2}" ;
        "z", "x", "v", "t", "r", "p", "n", "l", "j", "h", "f", "d", "b" },

    -- # make sure brace expansion handles ints > 2**31 - 1 using intmax_t
    { "{2147483645..2147483649}" ;
        "2147483645", "2147483646", "2147483647", "2147483648", "2147483649" },

    -- # unwanted zero-padding -- fixed post-bash-4.0
    { "{10..0..2}" ; "10", "8", "6", "4", "2", "0" },
    { "{10..0..-2}" ; "10", "8", "6", "4", "2", "0" },
    { "{-50..-0..5}" ;
        "-50", "-45", "-40", "-35", "-30", "-25", "-20", "-15", "-10", "-5", "0" },

    -- # bad
    { "{1..10.f}" ; "{1..10.f}" },
    { "{1..ff}" ; "{1..ff}" },
    { "{1..10..ff}" ; "{1..10..ff}" },
    { "{1.20..2}" ; "{1.20..2}" },
    { "{1..20..f2}" ; "{1..20..f2}" },
    { "{1..20..2f}" ; "{1..20..2f}" },
    { "{1..2f..2}" ; "{1..2f..2}" },
    { "{1..ff..2}" ; "{1..ff..2}" },
    { "{1..ff}" ; "{1..ff}" },
    { "{1..f}" ; "{1..f}" },
    { "{1..0f}" ; "{1..0f}" },
    { "{1..10f}" ; "{1..10f}" },
    { "{1..10.f}" ; "{1..10.f}" },
    { "{1..10.f}" ; "{1..10.f}" },


    -- Taken from https://github.com/trendels/braceexpand
    { '{1,2}' ; '1', '2' },
    { '{1}' ; '{1}' },
    { '{1,2{}}' ; '1', '2{}' },
    { '}{' ; '}{' },
    { 'a{b,c}d{e,f}' ; 'abde', 'abdf', 'acde', 'acdf' },
    { 'a{b,c{d,e,}}' ; 'ab', 'acd', 'ace', 'ac' },
    { 'a{b,{c,{d,e}}}' ; 'ab', 'ac', 'ad', 'ae' },
    { '{{a,b},{c,d}}' ; 'a', 'b', 'c', 'd' },
    { '{7..10}' ; '7', '8', '9', '10' },
    { '{10..7}' ; '10', '9', '8', '7' },
    { '{1..5..2}' ; '1', '3', '5' },
    { '{5..1..2}' ; '5', '3', '1' },
    { '{07..10}' ; '07', '08', '09', '10' },
    { '{7..010}' ; '007', '008', '009', '010' },
    { '{a..e}' ; 'a', 'b', 'c', 'd', 'e' },
    { '{a..e..2}' ; 'a', 'c', 'e' },
    { '{e..a}' ; 'e', 'd', 'c', 'b', 'a' },
    { '{e..a..2}' ; 'e', 'c', 'a' },
    { '{1..a}' ; '{1..a}' },
    { '{a..1}' ; '{a..1}' },
    { '{1..1}' ; '1' },
    { '{a..a}' ; 'a' },
    { '{,}' ; '', '' },

    -- These were fixed in this version
    { '{Z..a}' ; "Z", "[", "\\", "]", "^", "_", "`", "a" },
    { '{a..Z}' ; "a", "`", "_", "^", "]", "\\", "[", "Z" },

    -- Unbalanced braces
    { '{{1,2}' ; '{1', '{2' },
    { '{1,2}}' ; '1}', '2}' },
    { '{1},2}' ; '1}', '2' },
    { '{1,{2}' ; '{1,{2}' },
    { '{}1,2}' ; '{}1,2}' },
    { '{1,2{}' ; '{1,2{}' },
    { '}{1,2}' ; '}1', '}2' },
    { '{1,2}{' ; '1{', '2{' },

    -- escape_tests
    { '\\{1,2\\}' ; '\\{1,2\\}' },
    { '{1\\,2}' ; '{1\\,2}' },

    { '\\}{1,2}' ; '\\}1', '\\}2' },
    { '\\{{1,2}' ; '\\{1', '\\{2' },
    { '{1,2}\\}' ; '1\\}', '2\\}' },
    { '{1,2}\\{' ; '1\\{', '2\\{' },

    { '{\\,1,2}' ; '\\,1', '2' },
    { '{1\\,,2}' ; '1\\,', '2' },
    { '{1,\\,2}' ; '1', '\\,2' },
    { '{1,2\\,}' ; '1', '2\\,' },

    { '\\\\{1,2}' ; '\\\\1', '\\\\2' },

    { '\\{1..2\\}' ; '\\{1..2\\}' },
}

local function cmp_tables(a, b)
    if #a ~= #b then
        return false
    else
        for i, _ in ipairs(a) do
            if a[i] ~= b[i] then
                return false
            end
        end
    end

    return true
end

local function fmt(l)
    local r = {}
    for i, _ in ipairs(l) do
        r[i] = string.format("%q", l[i])
    end
    return table.concat(r, ', ')
end

for _, test in ipairs(tests) do
    local expr, good = test[1], { table.unpack(test, 2) }
    local result = brace_expand.expand(expr)
    if not cmp_tables(result, good) then
        print(string.format("For expression: %q", expr))
        print(string.format(" Got: %s", fmt(result)))
        print(string.format(" Expected: %s", fmt(good)))
    end
end

