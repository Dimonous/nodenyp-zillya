#<ACTION> file=>'web/zillya_adm.pl',hook=>'new'

use strict;

use nod::_zillya;
use Debug;
use JSON;

sub go
{
    my($Url) = @_;
    Adm->chk_privil_or_die('SuperAdmin');

    ToTop 'Административный модуль Zillya! Антивирус';


    $cfg::zillya_pass or Error(
        Adm->id? 'Zillya! plugin not configured' : $lang::user::temporarily_unavailable
    );

    $cfg::zillya_enabled or Error(
        Adm->id? 'Zillya! plugin disabled' : $lang::user::temporarily_unavailable
    );

    my $response = nod::zillya::api_request('get_keys');
    #my $keys_list = $response->{result};

    Show Center 'Получены данные:';
    if (exists($response->{'error'}))
    {
        Show Center $response->{'error'};
        Show Center $response->{'content'};

        # $response = nod::zillya::api_request('generate_test_key');
    }
    else
    {
        #Show Center $response->{'result'};
        my $result = decode_json($response->{'result'});
        my $status = $result->{'status'};
        if ( !( $status == 200) )
        {
            Show Center $status;
            Error ( $result->{'message'} );
        }
        my $licence_keys = $result->{'keys'};
        my $keys_tbl = tbl->new( -class=>'pretty td_tall td_wide width100' );
        $keys_tbl->add('head', 'llllllll',
            'Ключ',
            'Назва',
            'Створено',
            'Пристроїв',
            'Стан',
            'Активацій',
            'Термін',
            'Абонент',
        );
        for my $lic_record ( @$licence_keys )
        {
            my $pr = $lic_record->{'product'};
            my $product_name = '';
            if ( $pr == 1 ) {
                $product_name = 'ZILLYA ANTIVIRUS V3';
            } elsif ( $pr == 2 ) {
                $product_name = 'ZILLYA INTERNET SECURITY';
            } elsif ( $pr == 5 ) {
                $product_name = 'ZILLYA TOTAL SECURITY';
            }
            $keys_tbl->add('*', 'llllllllll',
                $lic_record->{'onlineKey'},
                $product_name,
                $lic_record->{'created'},
                $lic_record->{'devices'},
                $lic_record->{'licenceStatus'},
                $lic_record->{'activations'},
                $lic_record->{'period'},
                [$Url->a($lic_record->{'description'}, uid=>$lic_record->{'description'}, a=>'u_zillya')],
            );
        }
        Show Center $keys_tbl->show;



    }

}
1;
