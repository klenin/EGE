use strict;
use warnings;
use utf8;

use Test::More tests => 12;

use lib '..';

use EGE::Html;

is html->tag('a', 'b'), '<a>b</a>', 'simple tag';
is html->tag('br'), '<br/>', 'empty tag';
is html->tag('a', [ 'b', 'c', 'd' ]), '<a>bcd</a>', 'array body tag';
is html->tag('div', 'body', { color => 'red' }), '<div color="red">body</div>', 'simple attr';
is html->tag('div', 'body', { width => '1%', height => '2%' }),
    '<div height="2%" width="1%">body</div>', 'multi attr';
is html->tag('hr', undef, { width => '1px' }), '<hr width="1px"/>', 'empty tag attr';
is html->row('td', 1, 2, 3), '<tr><td>1</td><td>2</td><td>3</td></tr>', 'row';

is html->style(font => 'Arial', color => 'black'), 'color: black; font: Arial;', 'style';
is html->style(list_style => 'none'), 'list-style: none;', 'style _';

is
    html->div_xy('text', 7, 8, { margin => 0 }),
    '<div style="height: 8px; margin: 0; width: 7px;">text</div>', 'div_xy';

is html->ol_li([ 'a', 'b' ], { id => 'qq' }), '<ol id="qq"><li>a</li><li>b</li></ol>', 'ol_li';
is html->ul_li([ 'a', 'b' ], undef, { x => 'y' }), '<ul><li x="y">a</li><li x="y">b</li></ul>', 'ul_li';
