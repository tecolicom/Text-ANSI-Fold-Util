requires 'perl', 'v5.14';

requires 'List::Util', '1.45';
requires 'Text::ANSI::Fold', '1.08';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

