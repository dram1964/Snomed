#!/usr/bin/perl
use EHRS_Snomed::Model;
use Text::CSV;

my $csv = Text::CSV->new(
    {
        binary => 1,
        eol => "\r\n",
    }) or die "Cannot use CSV: " . Text::CSV->error_diag();

my $output = 'logs/fuzzy_match.csv';
open my $fh, ">:encoding(utf8)", $output or die "$output:$!";

my $double_quote = q/"/;
my $schema = EHRS_Snomed::Model->connect('CRIU_EHRS_Snomed');
my $debug = 4;

my $procedures = $schema->resultset('DentalDescription');
my $procedure_count = 0;
while (my $procedure = $procedures->next) {
    if ($debug <= 4) {
        print ++$procedure_count, ")",  $double_quote, $procedure->current_procedure, $double_quote,  "\n";
    }
    &find_matches($procedure );
    exit 0 if ($procedure_count > 10);
}
close $fh;


sub find_matches {
    my $procedure = shift;
    my @fields = qw/preferred_name synonym_1 synonym_2/;
    my $regex = qr/\b(is|of|or|to|and)\b/i;
    my @procedure_words = grep(!/$regex/, split/\s{1,}/, $procedure->current_procedure);
    my %procedure_words;
    for my $procedure_word (@procedure_words) {
            $procedure_word =~ s/\s*//;
            $procedure_word = lc($procedure_word);
            $procedure_words{$procedure_word} = 1;
    }
    my $procedure_word_count = scalar(keys %procedure_words);
    if ($debug <= 3 ) {
        print join(":", (keys %procedure_words)), "\n" if ($debug == 1);
        print scalar(keys %procedure_words), " Procedure Words found\n";
    }

    my $terms = $schema->resultset('TermsPivotted');
    while (my $term = $terms->next) {
        my %matches;
        for my $field (@fields) {
            if ($term->$field) {
                if ($debug <= 2 ) {
                    print $double_quote, $term->$field, $double_quote,  "\n";
                }
                my @match_words = grep(!/$regex/, split/\s{1,5}/, $term->$field);
                my %match_words;
                for my $match_word (@match_words) {
                    $match_word =~ s/\s*//;
                    $match_word = lc($match_word);
                    $match_words{$match_word} = 1;
                }
                my $match_word_count = scalar(keys %match_words);
                $matches{$field} = \%match_words;
                if ($debug <= 2) {
                    print join(":", (keys %{$matches{$field}})), "\n" if ($debug == 1);
                    print scalar(keys %{$matches{$field}}), " $field Words found\n";
                }

                my ($hit, $miss) = (0,0);
                for my $key (keys %match_words) {
                    if ($procedure_words{$key} == 1) {
                        $hit++;
                    }
                    else {
                        $miss++;
                    }
                }
                my $percent_match = $hit/$procedure_word_count * 100;
                my $percent_miss = $miss/$procedure_word_count * 100;
                if ($debug <= 3) {
                    if ($percent_match == 100 && $percent_miss == 0) {
                        print "Perfect match: ", $double_quote,  $term->$field, $double_quote, " to ", 
                            $double_quote, $procedure->current_procedure, $double_quote, "\n";
                    }
                    elsif ($percent_match == 0 && $percent_miss >= 100) {
                        print "No match: ", $double_quote, $term->$field, $double_quote, " to ", 
                            $double_quote, $procedure->current_procedure, $double_quote, "\n";
                    }
                    else {
                        print "$hit Matches: $miss Misses for ", $double_quote, $term->$field, $double_quote, 
                            " to ", $double_quote, $procedure->current_procedure, $double_quote, "\n";
                    }
                }
                if ($percent_match == 100 && $percent_miss == 0) {
                    print "Perfect match: ", $double_quote,  $term->$field, $double_quote, " to ", 
                        $double_quote, $procedure->current_procedure, $double_quote, "\n";
                    $csv->print($fh, $_) for [
                        $percent_match,
                        $procedure->current_procedure,
                        $procedure->specialty,
                        $procedure->number_of_specialties,
                        $term->concept_id,
                        $term->preferred_name_id,
                        $term->preferred_name,
                        $term->synonym_id_1,
                        $term->synonym_1,
                        $term->synonym_id_2,
                        $term->synonym_2,
                        $term->synonym_id_3,
                        $term->synonym_3,
                        $term->synonym_id_4,
                        $term->synonym_4,
                        $term->synonym_id_5,
                        $term->synonym_5,
                        $term->synonym_id_6,
                        $term->synonym_6,
                        $term->synonym_id_7,
                        $term->synonym_7,
                        $term->synonym_id_8,
                        $term->synonym_8,
                        $term->synonym_id_9,
                        $term->synonym_9,
                        $term->synonym_id_10,
                        $term->synonym_10,
                        $term->synonym_id_11,
                        $term->synonym_11,
                        $term->synonym_id_12,
                        $term->synonym_12,
                        $term->synonym_id_13,
                        $term->synonym_13,
                        $term->synonym_id_14,
                        $term->synonym_14,
                        $term->synonym_id_15,
                        $term->synonym_15,
                        $term->synonym_id_16,
                        $term->synonym_16,
                        $term->synonym_id_17,
                        $term->synonym_17,
                        ]

                }

            }
        }
    }
}
