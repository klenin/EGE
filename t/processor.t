use strict;
use warnings;

use Test::More tests => 245;
use Test::Exception;

use lib '..';
use EGE::Bits;
use EGE::Asm::Processor;

sub check_stack {
    my @stack = @_;
    return '' if $#{proc->{stack}} != $#stack;
    my $res = 1;
    for my $i (0..$#stack) {
        $res = '' if ($stack[$i] !=  proc->{stack}->[$i])
    }
    $res;
}

{
    for my $r (@EGE::Asm::Processor::registers) {
        proc->run_code([ ['mov', $r, 9999999] ]);
        is proc->get_val($r), 9999999, "mov $r";
    }
    throws_ok { proc->get_register('zzz'); } qr/zzz/, 'unknown register';
}

{
    proc->run_code([ ['mov', 'al', 98] ]);
    is proc->get_val('eax'), 98, 'mov al';
    proc->run_code([ ['mov', 'ah', 98] ]);
    is proc->get_val('eax'), 25088, 'mov ah';
    proc->run_code([ ['mov', 'al', -56] ]);
    is proc->get_val('eax'), 200, 'mov negative number';
    proc->run_code([ ['mov', 'al', 256] ]);
    is proc->get_val('eax'), 0, 'mov overflow number';
    is proc->{eflags}->flags_text, '', 'mov set flags';
    proc->run_code([ ['mov', 'ax', 256] ]);
    is proc->get_val('eax'), 256, 'mov ax';
    proc->run_code([ ['mov', 'eax', 256] ]);
    is proc->get_val('eax'), 256, 'mov eax';
    proc->run_code([ ['mov', 'al', 209], ['movzx', 'ax', 'al'] ]);
    is proc->get_val('eax'), 209, 'movzx';
    proc->run_code([ ['mov', 'al', 209], ['movsx', 'ax', 'al'] ]);
    is proc->get_val('eax'), 65489, 'movsx';
    my $w = proc->get_wrong_val('eax') ^ proc->get_val('eax');
    ok $w && !($w & ($w - 1)), 'wrong value';
}

{
    proc->run_code([ ['mov', 'al', 15], ['add', 'al', 7] ]);
    is proc->get_val('eax'), 22, 'add positive number';
    is proc->{eflags}->flags_text, '', 'add set flags';

    proc->run_code([ ['mov', 'ah', 15], ['add', 'ah', 7] ]);
    is proc->get_val('eax'), 22 * 256, 'add to ah';
    is proc->{eflags}->flags_text, '', 'add to ah set flags';

    proc->run_code([ ['mov', 'ah', 16], ['add', 'ah', 7] ]);
    is proc->get_val('eax'), 23 * 256, 'add to ah (2)';
    is proc->{eflags}->flags_text, 'PF', 'add to ah set flags (2)';

    proc->run_code([ ['mov', 'al', 15], ['add', 'al', -7] ]);
    is proc->get_val('eax'), 8, 'add negative less number';
    is proc->{eflags}->flags_text, 'CF', 'add negative less number set flags';
    proc->run_code([ ['mov', 'al', 15], ['add', 'al', -17] ]);
    is proc->get_val('eax'), 254, 'add negative greater number';
    is proc->{eflags}->flags_text, 'SF', 'add negative greater number set flags';
    proc->run_code([ ['mov', 'al', 129], ['add', 'al', 127] ]);
    is proc->get_val('eax'), 0, 'add negative and positive numbers to receive positive';
    is proc->{eflags}->flags_text, 'CF PF ZF', 'add negative and positive numbers to receive positive set flags';
    proc->run_code([ ['mov', 'al', 128], ['add', 'al', 128] ]);
    is proc->get_val('eax'), 0, 'add negative numbers to receive positive';
    is proc->{eflags}->flags_text, 'CF OF PF ZF', 'add negative numbers to receive positive set flags';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 63] ]);
    is proc->get_val('eax'), 127, 'add positive numbers to receive positive';
    is proc->{eflags}->flags_text, '', 'add positive numbers to receive positive set flags';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 64] ]);
    is proc->get_val('eax'), 128, 'add positive numbers to receive negative';
    is proc->{eflags}->flags_text, 'OF SF', 'add positive numbers to receive negative set flags';
}

{
    proc->run_code([ ['stc'] ]);
    is proc->{eflags}->flags_text, 'CF', 'stc';
    proc->run_code([ ['stc'], ['clc'] ]);
    is proc->{eflags}->flags_text, '', 'clc';
    proc->run_code([ ['mov', 'al', 15], ['stc'], ['adc', 'al', 7] ]);
    is proc->get_val('eax'), 23, 'stc adc';
    proc->run_code([ ['mov', 'al', 15], ['clc'], ['adc', 'al', 7] ]);
    is proc->get_val('eax'), 22, 'clc adc';
    proc->run_code([ ['mov', 'al', 250], ['clc'], ['adc', 'al', 10] ]);
    is proc->get_val('eax'), 4, 'clc adc set CF';
    is proc->{eflags}->flags_text, 'CF', 'clc adc set CF flags';
    proc->run_code([ ['mov', 'al', 250], ['stc'], ['adc', 'al', 10] ]);
    is proc->get_val('eax'), 5, 'stc adc set CF';
    is proc->{eflags}->flags_text, 'CF PF', 'stc adc set CF flags';
    proc->run_code([ ['mov', 'al', 250], ['stc'], ['adc', 'al', 5] ]);
    is proc->get_val('eax'), 0, 'stc adc to 0';
    is proc->{eflags}->flags_text, 'CF PF ZF', 'stc adc to 0 flags';
}

{
    proc->run_code([ ['mov', 'al', 15], ['sub', 'al', 7] ]);
    is proc->get_val('eax'), 8, 'sub positive numbers to receive positive';
    is proc->{eflags}->flags_text, '', 'sub positive numbers to receive positive flags';
    proc->run_code([ ['mov', 'al', 7], ['sub', 'al', 15] ]);
    is proc->get_val('eax'), 248, 'sub positive numbers to receive negative';
    is proc->{eflags}->flags_text, 'CF SF', 'sub positive numbers to receive positive flags';
    proc->run_code([ ['mov', 'al', 7], ['sub', 'al', 7] ]);
    is proc->get_val('eax'), 0, 'sub positive numbers to receive zero';
    is proc->{eflags}->flags_text, 'PF ZF', 'sub positive numbers to receive zero flags';
    proc->run_code([ ['mov', 'al', -1], ['sub', 'al', -3] ]);
    is proc->get_val('eax'), 2, 'sub negative numbers to receive positive';
    is proc->{eflags}->flags_text, '', 'sub negative numbers to receive positive flags';
    proc->run_code([ ['mov', 'al', -3], ['sub', 'al', -1] ]);
    is proc->get_val('eax'), 254, 'sub negative numbers to receive negative';
    is proc->{eflags}->flags_text, 'CF SF', 'sub negative numbers to receive positive flags';
    proc->run_code([ ['mov', 'al', 15], ['sub', 'al', -7] ]);
    is proc->get_val('eax'), 22, 'sub positive and negative numbers';
    is proc->{eflags}->flags_text, 'CF', 'sub positive and negative numbers flags';
    proc->run_code([ ['mov', 'al', -7], ['sub', 'al', 15] ]);
    is proc->get_val('eax'), 234, 'sub negative and positive numbers';
    is proc->{eflags}->flags_text, 'SF', 'sub negative and positive numbers flags';
    proc->run_code([ ['mov', 'al', 64], ['sub', 'al', -63] ]);
    is proc->get_val('eax'), 127, 'sub do not set OF';
    is proc->{eflags}->flags_text, 'CF', 'sub do not set OF flags';
    proc->run_code([ ['mov', 'al', 64], ['sub', 'al', -64] ]);
    is proc->get_val('eax'), 128, 'sub set OF';
    is proc->{eflags}->flags_text, 'CF OF SF', 'sub set OF flags';
    proc->run_code([ ['mov', 'al', -64], ['sub', 'al', 64] ]);
    is proc->get_val('eax'), 128, 'sub do not set OF';
    is proc->{eflags}->flags_text, 'SF', 'sub do not set OF flags';
    proc->run_code([ ['mov', 'al', -64], ['sub', 'al', 65] ]);
    is proc->get_val('eax'), 127, 'sub set OF';
    is proc->{eflags}->flags_text, 'OF', 'sub set OF flags';
    proc->run_code([ ['mov', 'eax', 1], ['sub', 'eax', 2] ]);
    is proc->get_val('eax'), 0xFFFFFFFF, 'sub positive eax to receive negative';
    is proc->{eflags}->flags_text, 'CF PF SF', 'sub positive eax to receive positive flags';
}

{
    sub test_cmp {
        my ($v1, $v2, $flags) = @_;
        proc->run_code([ ['mov', 'al', $v1], ['cmp', 'al', $v2] ]);
        is proc->{eflags}->flags_text, $flags, "cmp: $v1 ? $v2";
    }
    test_cmp(1, 1, 'PF ZF');
    test_cmp(0, 1, 'CF PF SF');
    test_cmp(1, 0, '');
    test_cmp(0, -1, 'CF');
    test_cmp(128, 127, 'OF');
    test_cmp(64, -64, 'CF OF SF');
}


{
    proc->run_code([ ['mov', 'al', 15], ['stc'], ['sbb', 'al', 7] ]);
    is proc->get_val('eax'), 7, 'stc sbb to recieve positive';
    proc->run_code([ ['mov', 'al', 15], ['clc'], ['sbb', 'al', 7] ]);
    is proc->get_val('eax'), 8, 'clc sbb to recieve positive';
    proc->run_code([ ['mov', 'al', 7], ['stc'], ['sbb', 'al', 15] ]);
    is proc->get_val('eax'), 247, 'stc sbb to recieve negative';
    proc->run_code([ ['mov', 'al', 7], ['clc'], ['sbb', 'al', 15] ]);
    is proc->get_val('eax'), 248, 'clc sbb to recieve negative';
    proc->run_code([ ['mov', 'al', 7], ['stc'], ['sbb', 'al', 7] ]);
    is proc->get_val('eax'), 255, 'stc sbb equal numbers';
    is proc->{eflags}->flags_text, 'CF PF SF', 'stc sbb equal numbers flags';
    proc->run_code([ ['xor', 'ebx', 'ebx'], ['stc'], ['sbb', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 0xFFFFFFFF, 'stc sbb eax zero';
    is proc->{eflags}->flags_text, 'CF PF SF', 'stc sbb eax zero flags';
}

{
    proc->run_code([ ['mov', 'al', 7], ['neg', 'al'] ]);
    is proc->get_val('eax'), 249, 'neg positive';
    is proc->{eflags}->flags_text, 'CF PF SF', 'neg positive flags';
    proc->run_code([ ['mov', 'al', -7], ['neg', 'al'] ]);
    is proc->get_val('eax'), 7, 'neg negative';
    is proc->{eflags}->flags_text, 'CF', 'neg negative flags';
    proc->run_code([ ['mov', 'al', 0], ['neg', 'al'] ]);
    is proc->get_val('eax'), 0, 'neg zero';
    is proc->{eflags}->flags_text, 'PF ZF', 'neg zero flags';
}

{
    proc->run_code([ ['mov', 'al', 209], ['mov', 'bh', 10], ['add', 'al', 'bh'] ]);
    is proc->get_val('eax'), 219, 'add register';
    proc->run_code([ ['mov', 'al', 55], ['add', 'al', 15], ['sub', 'al', 4] ]);
    is proc->get_val('eax'), 66, 'add sub';
    proc->run_code([ ['mov', 'al', 178], ['sub', 'al', 21], ['mov', 'dh', 5], ['add', 'al', 'dh'] ]);
    is proc->get_val('eax'), 162, 'sub add register';
}

{
    proc->run_code([ ['mov', 'ax', 10], ['imul', 'ax', 15] ]);
    is proc->get_val('eax'), 150, 'imul';
}

{
    proc->run_code([ ['mov', 'al', 209], ['stc'], ['and', 'al', 237] ]);
    is proc->get_val('eax'), 193, 'and';
    is proc->{eflags}->flags_text, 'SF', 'and flags';
    proc->run_code([ ['mov', 'al', 209], ['stc'], ['or', 'al', 141] ]);
    is proc->get_val('eax'), 221, 'or';
    is proc->{eflags}->flags_text, 'PF SF', 'or flags';
    proc->run_code([ ['mov', 'al', 209], ['stc'], ['xor', 'al', 13] ]);
    is proc->get_val('eax'), 220, 'xor';
    is proc->{eflags}->flags_text, 'SF', 'xor flags';
    proc->run_code([ ['mov', 'al', 209], ['stc'], ['test', 'al', 2] ]);
    is proc->get_val('eax'), 209, 'test';
    is proc->{eflags}->flags_text, 'PF ZF', 'test flags';
    proc->run_code([ ['mov', 'al', 13], ['not', 'al'] ]);
    is proc->get_val('eax'), 242, 'not';
    is proc->{eflags}->flags_text, '', 'not flags';
    proc->run_code([ ['mov', 'eax', 3482736], ['mov', 'ebx', 'eax'], ['not', 'ebx'], ['and', 'ebx', 'eax'] ]);
    is proc->get_val('ebx'), 0, 'and-not';
    is proc->{eflags}->flags_text, 'PF ZF', 'and-not flags';
}

{
    proc->run_code([ ['mov', 'al', 209], ['shl', 'al', 2] ]);
    is proc->get_val('eax'), 68, 'shl';
    is proc->{eflags}->flags_text, 'CF PF', 'shl flags';
    proc->run_code([ ['mov', 'cx', 0xDFB0], ['shl', 'ch', 4] ]);
    is proc->get_val('ecx'), 0xF0B0, 'shl cx';
    is proc->{eflags}->flags_text, 'CF PF SF', 'shl cx flags';

    proc->run_code([ ['mov', 'al', 209], ['shr', 'al', 2] ]);
    is proc->get_val('eax'), 52, 'shr';
    is proc->{eflags}->flags_text, '', 'shr flags';
    proc->run_code([ ['mov', 'cx', 0xCFB0], ['shr', 'cl', 4] ]);
    is proc->get_val('ecx'), 0xCF0B, 'shr cx';
    is proc->{eflags}->flags_text, '', 'shr cx flags';
    proc->run_code([ ['mov', 'edx', 0xFFFFFF], ['shr', 'dh', 1] ]);
    is proc->get_val('edx'), 0xFF7FFF, 'shr dh';
    is proc->{eflags}->flags_text, 'CF OF', 'shr dh flags';
    proc->run_code([ ['mov', 'edx', 0x12345678], ['shr', 'edx', 36] ]);
    is proc->get_val('edx'), 0x1234567, 'shr mod 32';

    proc->run_code([ ['mov', 'al', 209], ['sal', 'al', 2] ]);
    is proc->get_val('eax'), 68, 'sal';
    is proc->{eflags}->flags_text, 'CF PF', 'sal flags';
    proc->run_code([ ['mov', 'cx', 0xDFB0], ['sal', 'ch', 4] ]);
    is proc->get_val('ecx'), 0xF0B0, 'sal cx';
    is proc->{eflags}->flags_text, 'CF PF SF', 'sal cx flags';

    proc->run_code([ ['mov', 'al', 209], ['sar', 'al', 2] ]);
    is proc->get_val('eax'), 244, 'sar';
    is proc->{eflags}->flags_text, 'SF', 'sar flags';
    proc->run_code([ ['mov', 'edx', 0xFF81FF], ['sar', 'dh', 1] ]);
    is proc->get_val('edx'), 0xFFC0FF, 'sar dh';
    is proc->{eflags}->flags_text, 'CF PF SF', 'sar dh flags';
    proc->run_code([ ['mov', 'ax', 0x8000], ['sar', 'ax', 33] ]);
    is proc->get_val('ax'), 0xC000, 'sar mod 32';

    proc->run_code([ ['mov', 'al', 209], ['rol', 'al', 2] ]);
    is proc->get_val('eax'), 71, 'rol';
    is proc->{eflags}->flags_text, 'CF PF', 'rol flags';
    proc->run_code([ ['mov', 'al', 209], ['ror', 'al', 2] ]);
    is proc->get_val('eax'), 116, 'ror';
    is proc->{eflags}->flags_text, 'PF', 'ror flags';
    proc->run_code([ ['mov', 'al', 209], ['clc'], ['rcl', 'al', 2] ]);
    is proc->get_val('eax'), 69, 'clc rcl';
    is proc->{eflags}->flags_text, 'CF', 'clc rcl flags';
    proc->run_code([ ['mov', 'al', 209], ['stc'], ['rcl', 'al', 2] ]);
    is proc->get_val('eax'), 71, 'stc rcl';
    is proc->{eflags}->flags_text, 'CF PF', 'stc rcl flags';
    proc->run_code([ ['mov', 'al', 209], ['clc'], ['rcr', 'al', 2] ]);
    is proc->get_val('eax'), 180, 'clc rcr';
    is proc->{eflags}->flags_text, 'PF SF', 'clc rcr flags';
    proc->run_code([ ['mov', 'al', 209], ['stc'], ['rcr', 'al', 2] ]);
    is proc->get_val('eax'), 244, 'stc rcr';
    is proc->{eflags}->flags_text, 'SF', 'stc rcr flags';
    proc->run_code([ ['mov', 'dx', 128], ['mov', 'cl', 3], ['shr', 'dx'] ]);
    is proc->get_val('edx'), 16, 'shr cl';
}

{
    proc->run_code([ ['mov', 'al', 1], ['jmp', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jmp';
    proc->run_code([ ['mov', 'al', 1], ['stc'], ['jc', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jc pass';
    proc->run_code([ ['mov', 'al', 1], ['clc'], ['jc', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jc not pass';
    proc->run_code([ ['mov', 'al', 1], ['stc'], ['jnc', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnc not pass';
    proc->run_code([ ['mov', 'al', 1], ['clc'], ['jnc', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jnc pass';
    proc->run_code([ ['mov', 'al', 1], ['add', 'al', 4], ['jp', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 5, 'jp pass';
    proc->run_code([ ['mov', 'al', 1], ['add', 'al', 1], ['jp', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jp not pass';
    proc->run_code([ ['mov', 'al', 1], ['add', 'al', 4], ['jnp', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnp not pass';
    proc->run_code([ ['mov', 'al', 1], ['add', 'al', 1], ['jnp', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 2, 'jnp pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 1], ['jz', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jz pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 0], ['jz', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jz not pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 1], ['jnz', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnz not pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 0], ['jnz', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jnz pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 64], ['js', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 128, 'js pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 1], ['js', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'js not pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 64], ['jns', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jns not pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 1], ['jns', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 65, 'jns pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 64], ['jo', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 128, 'jo pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 1], ['jo', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jo not pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 64], ['jno', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jno not pass';
    proc->run_code([ ['mov', 'al', 64], ['add', 'al', 1], ['jno', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 65, 'jno pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 1], ['je', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'je pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 0], ['je', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'je not pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 1], ['jne', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jne not pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 0], ['jne', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jne pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', 1], ['jl', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 253, 'jl pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jl', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jl not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', 1], ['jnl', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnl not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jnl', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jnl pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jle', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jle pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -3], ['jle', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jle not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jnle', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnle not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -3], ['jnle', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jnle pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -3], ['jg', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 1, 'jg pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jg', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jg not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -3], ['jng', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jng not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jng', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jng pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jge', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jge pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -1], ['jge', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jge not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -2], ['jnge', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnge not pass';
    proc->run_code([ ['mov', 'al', -2], ['sub', 'al', -1], ['jnge', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 255, 'jnge pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 1], ['ja', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 164, 'ja pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['ja', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'ja not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 1], ['jna', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jna not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jna', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jna pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jae', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jae pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 166], ['jae', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jae not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jnae', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnae not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 166], ['jnae', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 255, 'jnae pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 165], ['jb', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 92, 'jb pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jb', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jb not pass';
    proc->run_code([ ['mov', 'al', 1], ['sub', 'al', 165], ['jnb', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnb not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jnb', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jnb pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jbe', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 0, 'jbe pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 1], ['jbe', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jbe not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 165], ['jnbe', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 3, 'jnbe not pass';
    proc->run_code([ ['mov', 'al', 165], ['sub', 'al', 1], ['jnbe', 'm'], ['mov', 'al', 3], ['m:'] ]);
    is proc->get_val('eax'), 164, 'jnbe pass';
}

{
    proc->run_code([ ['mov', 'al', 0], ['L1:'], ['add', 'al', 1], ['jno', 'L1'] ]);
    is proc->get_val('eax'), 128, 'loop until OF';
    is proc->{eflags}->flags_text, 'OF SF', 'loop until OF flags';
    proc->run_code([ ['L1:'], ['L2:'], ['add', 'al', 8], ['jz', 'L3'], ['jp', 'L1'], ['jnp', 'L2'], ['L3:']]);
    is proc->get_val('eax'), 0, 'double label';
    ok !eval { proc->run_code([ ['jmp', 'L'] ]); 1 }, 'non-existing label';
}

{
    proc->run_code([ ['mov', 'al', 1], ['push', 'al'] ]);
    ok check_stack(1), 'push';
    proc->run_code([ ['mov', 'al', 1], ['push', 'al'], ['mov', 'al', 2], ['push', 'al'] ]);
    ok check_stack(2, 1), 'double push';
    proc->run_code([ ['mov', 'al', 1], ['push', 'al'], ['pop', 'bl'] ]);
    is proc->get_val('ebx'), 1, 'pop';
    ok check_stack(), 'pop stack';
    proc->run_code([ ['mov', 'al', 1], ['push', 'al'], ['mov', 'al', 2], ['push', 'al'], ['pop', 'bl'] ]);
    is proc->get_val('ebx'), 2, 'double push pop';
    ok check_stack(1), 'double push pop stack';
}

{
    proc->run_code([ ['mov', 'ebx', 0xDE5647C8], ['bsr', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 31, 'bsr test 1';
    is proc->{eflags}->flags_text, 'ZF', 'bsr flags test 1';
    is (0xDE5647C8, proc->get_val('ebx'), 'bsr ebx unchanged 1');
    proc->run_code([ ['mov', 'ebx', 0x28E2E288], ['bsr', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 29, 'bsr test 2';
    is proc->{eflags}->flags_text, 'ZF', 'bsr flags test 2';
    proc->run_code([ ['mov', 'ebx', 0xCA288], ['bsr', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 19, 'bsr test 3';
    is proc->{eflags}->flags_text, 'ZF', 'bsr flags test 3';
    proc->run_code([ ['mov', 'ebx', 0x00000000], ['bsr', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 0, 'bsr test 4';
    is proc->{eflags}->flags_text, '', 'bsr flags test 4';
    proc->run_code([ ['mov', 'bx', 0xC280], ['bsr', 'ax', 'bx'] ]);
    is proc->get_val('ax'), 15, 'bsr test 5';
    is proc->{eflags}->flags_text, 'ZF', 'bsr flags test 5';
    proc->run_code([ ['mov', 'bx', 0x0000], ['bsr', 'ax', 'bx'] ]);
    is proc->get_val('ax'), 0, 'bsr test 6';
    is proc->{eflags}->flags_text, '', 'bsr flags test 6';

    proc->run_code([ ['mov', 'ebx', 0xDE5647C8], ['bsf', 'ebx', 'ebx'] ]);
    is proc->get_val('ebx'), 3, 'bsf test 1';
    is proc->{eflags}->flags_text, 'ZF', 'bsf flags test 1';
    proc->run_code([ ['mov', 'ebx', 0x28E2E2A0], ['bsf', 'ebx', 'ebx'] ]);
    is proc->get_val('ebx'), 5, 'bsf test 2';
    is proc->{eflags}->flags_text, 'ZF', 'bsf flags test 2';
    proc->run_code([ ['mov', 'ebx', 0xCA280], ['bsf', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 7, 'bsf test 3';
    is proc->{eflags}->flags_text, 'ZF', 'bsf flags test 3';
    is (0xCA280, proc->get_val('ebx'), 'bsr ebx unchanged 2');
    proc->run_code([ ['mov', 'ebx', 0x00000000], ['bsf', 'eax', 'ebx'] ]);
    is proc->get_val('eax'), 0, 'bsf test 4';
    is proc->{eflags}->flags_text, '', 'bsf flags test 4';
    proc->run_code([ ['mov', 'bx', 0xC200], ['bsf', 'ax', 'bx'] ]);
    is proc->get_val('ax'), 9, 'bsf test 5';
    is proc->{eflags}->flags_text, 'ZF', 'bsf flags test 5';
    proc->run_code([ ['mov', 'bx', 0x0000], ['bsf', 'ax', 'bx'] ]);
    is proc->get_val('ax'), 0, 'bsf test 6';
    is proc->{eflags}->flags_text, '', 'bsf flags test 6';
}

{
    proc->run_code([ ['mov', 'ax', 250], ['mov', 'bl', 150], ['div', 'bl'] ]);
    is proc->get_val('al'), 1, 'div test 8-bit argument: quotient';
    is proc->get_val('ah'), 100, 'div test 8-bit argument: remainder';
    throws_ok { proc->run_code([ ['mov', 'ax', 2**15], ['mov', 'bl', 1], ['div', 'bl'] ]); } qr/quotient is too big/ , '#DE 8-bit argument';
    throws_ok { proc->run_code([ ['mov', 'ax', 2**15], ['mov', 'bl', 0], ['div', 'bl'] ]); } qr/Illegal division by zero/ , '#DE 8-bit argument';
    
    proc->run_code([ ['mov', 'dx', 762], ['mov', 'ax', 61568], ['mov', 'bx', 60000], ['div', 'bx'] ]);
    is proc->get_val('ax'), 833, 'div test 16-bit argument: divisor';
    is proc->get_val('dx'), 20000, 'div test 16-bit argument: remainder';
    throws_ok { proc->run_code([ ['mov', 'dx', 2**15], ['mov', 'ax', 2**15], ['mov', 'bx', 1], ['div', 'bx'] ]); } qr/quotient is too big/ , '#DE 16-bit argument';
    throws_ok { proc->run_code([ ['mov', 'dx', 2**15], ['mov', 'ax', 2**15], ['mov', 'bx', 0], ['div', 'bx'] ]); } qr/Illegal division by zero/ , '#DE 16-bit argument';
    
    proc->run_code([ ['mov', 'edx', 2**7], ['mov', 'eax', 2**31 + 2**16], ['mov', 'ebx', 2**31 + 1], ['div', 'ebx'] ]);
    is proc->get_val('eax'), 2**8 + 1, 'div test 32-bit argument: divisor';
    is proc->get_val('edx'), 65279, 'div test 32-bit argument: divisor';
    throws_ok { proc->run_code([ ['mov', 'edx', 2**7], ['mov', 'eax', 2**31 + 2**16], ['mov', 'ebx', 1], ['div', 'ebx'] ]); } qr/quotient is too big/ , '#DE 32-bit argument';
    throws_ok { proc->run_code([ ['mov', 'edx', 2**7], ['mov', 'eax', 2**31 + 2**16], ['mov', 'ebx', 0], ['div', 'ebx'] ]); } qr/Illegal division by zero/ , '#DE 32-bit argument';
}