use DBIx::Class::Schema::Loader qw/ make_schema_at /;

make_schema_at(
    'EHRS_Snomed::Schema',
    {
        debug          => 1,
        dump_directory => './lib',
    },
    [
        'dbi:ODBC:DSN=CRIU_EHRS_Snomed',
        'user', 'password', { LongReadLen => 180, LongTruncOk => 1 }
    ],
);
