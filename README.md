#EGE: Elementary Generator Engine
[![Travis Build Status](https://travis-ci.org/klenin/EGE.svg)](https://travis-ci.org/klenin/EGE)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/klenin/ege?svg=true)](https://ci.appveyor.com/project/klenin/EGE)
[![Coverage Status](https://coveralls.io/repos/github/klenin/EGE/badge.svg)](https://coveralls.io/github/klenin/EGE)

Система генерации тестовых заданий по различным предметам,
связанным информатикой и математикой.

Содержит модули "Задания ЕГЭ", "Архитектура процессоров Intel", "Язык SQL" и др.

Может быть использована как автономно, так и в составе системы автоматизированного тестирования знаний, например [AWorks].

Сгенерированные задания могут быть сохранены в формате HTML либо .quiz (см. [AQuiz])

Порядок установки:
  1. Установить Perl 5.10 или более новый
  2. Склонировать репозиторий
  3. В файле ```gen.pl``` раскомментировать строки, соответствующие нужным тестам (например ```$questions = EGE::Generate::all```)
  4. Запустить ```perl gen.pl >test.xhtml```
  5. Открыть файл ```test.xhtml``` в браузере, например ```firefox test.xhtml```

Система распространяется под лицензией GPL версии 2 или более поздней.

[AWorks]:http://imcs.dvfu.ru/works
[AQuiz]:http://github.com/klenin/AQuiz
