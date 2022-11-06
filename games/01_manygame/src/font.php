<?php

$n = 0x30;
$src = imagecreatefrompng("font.png");
$font = [];

for ($y = 0; $y < 24; $y += 8) {

    for ($x = 0; $x < 128; $x += 8) {

        for ($i = 0; $i < 8; $i++) {

            $mask = 0;
            for ($j = 0; $j < 8; $j++) {

                $cl = imagecolorat($src, $x + $j, $y + $i);
                if ($cl) $mask |= (0x80 >> $j);
            }

            $font[$n][] = sprintf("0x%02X", $mask);
        }

        $n++;
    }
}

foreach ($font as $rows) {
    echo "{".join(', ', $rows)."},\n";
}
