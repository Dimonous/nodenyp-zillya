#<ACTION> file=>'web/user/zillya.pl',hook=>'new'
# ------------------- NoDeny ------------------
#  (с) Volik Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
# ------------------- Boryspil.net ------------
#  (с) Dmytro Vasyk (http://dmytrovasyk.com)
# ---------------------------------------------
use strict;

use nod::_zillya;
use Debug;
use JSON;
use services;

sub go
{
    my($Url, $usr, $lang) = @_;

    my $uid = $usr->{id};
    #if ($uid != 5004)
    #{
    #    Error('Module in development');
    #}

    !$ses::api && !$ses::auth->{trust} && Error($lang::err_need_trust_auth.' '.url->a($lang::Now, a=>'logout'));

    $cfg::zillya_pass or Error(
        Adm->id? 'Zillya! plugin not configured' : $lang::user::temporarily_unavailable
    );

    $cfg::zillya_enabled or Error(
        Adm->id? 'Zillya! plugin disabled' : $lang::user::temporarily_unavailable
    );

    my $act = ses::input('act');

    if( $act eq 'disable' )
    {
        my $response = nod::zillya::api_request('disable_licence', $uid, ses::input('id'), 0 );
        Show Center 'Результат виконання запиту:';
        if (exists($response->{'error'}))
        {
            Show Center $response->{'content'};
            Error ( $response->{'error'} );
        }
        else
        {
            #Show Center $response->{'result'};

            my $db = Db->sql( "SELECT id FROM users_services WHERE uid=? AND service_id IN (145, 148, 151) ", $uid );
            Db->ok or Error $lang::user::soft_error;
            while( my %p = $db->line )
            {
                my $err = services->proc(
                    cmd  => 'end',
                    uid  => $uid,
                    id   => $p{id},
                );
                if( $err ) {
                    Error ('warn', $lang::services_pm->{$err->{for_adm}} || $err->{for_adm});
                    my $made_msg .= ' '.L('didnt_made').': '.($lang::services_pm->{$err->{for_usr}} || $err->{for_usr} || $lang::user::soft_error);
                    Error $made_msg;
                }
            }
            Show Center 'Передплату скасовано';
        }

    }


    if( $act eq 'subscribe' )
    {
        my $product = ses::input('product');
        my $service_id;
        if ($product == 1) {
            $service_id = 145;
        } elsif ($product == 2) {
            $service_id = 148;
        } elsif ($product == 5) {
            $service_id = 151;
        } else {
            Error ('Невідомий product_id');
        }
        my $err = services->proc(
            cmd         => 'add',
            # по таблице user_services id уже подключенной услуги. Если cmd = 'add' - игнорируется 
            id          => ses::input_int('usr_service_id'),
            uid         => $uid,
            service_id  => $service_id,
            creator     => {
                type => 'other',
                id   => $uid,
                ip   => $ses::ip,
            },
        );
        if( $err ) {
            Error ('warn', $lang::services_pm->{$err->{for_adm}} || $err->{for_adm});
            my $made_msg .= ' '.L('didnt_made').': '.($lang::services_pm->{$err->{for_usr}} || $err->{for_usr} || $lang::user::soft_error);
            Error $made_msg;
        }

        my $db = Db->sql( "SELECT (tm_end - tm_start)/3600/24 AS tm FROM users_services WHERE uid=? AND service_id IN (145, 148, 151) LIMIT 1", $uid );
        Db->ok or Error $lang::user::soft_error;
        my $period;
        while( my %p = $db->line )
        {
            $period = $p{tm};
        }
        my $response = nod::zillya::api_request('add_licence', $uid, $product, $period );
        #Show Center 'Результат виконання запиту:';
        if (exists($response->{'error'}))
        {
            Show Center $response->{'content'};
            Error ( $response->{'error'} );
        }
        else
        {
            # Show Center $response->{'result'};
            Show Center 'Передплату на послугу здійснено успішно';
        }

    }




#    my $response = nod::zillya::api_request('get_licences_for_uid', 'ich@email.me', $uid, 'ich@email.me' );
    my $response = nod::zillya::api_request('get_licences_for_uid', $uid, '', 0 );

    #Show Center 'Контекст:';
    #Show Center $response->{'context'};
    if (exists($response->{'error'}))
    {
        my $status = $response->{'code'};
        if ( !($status == 404) )
        {
            Error ( $response->{'error'} );
        }
        Show Center "Передплата на послугу антивіруса відсутня. Підключіть послугу через меню зліва і на цій сторінці отримайте ключ ліцензії";
        Show '';

        #my $add_tbl = tbl->new( -class=>'pretty td_tall td_wide width100' );
        #$add_tbl->add('head', 'lllll',
        #  'Назва',
        #  'Ціна, грн./міс.',
        #  ''
        #);
        #$add_tbl->add('*', 'lll', 'ZILLYA ANTIVIRUS V3', '10', [$Url->a('Підключити', act=>'subscribe', product=>1)] );
        #$add_tbl->add('*', 'lll', 'ZILLYA INTERNET SECURITY', '17', [$Url->a('Підключити', act=>'subscribe', product=>2)]);
        #$add_tbl->add('*', 'lll', 'ZILLYA TOTAL SECURITY', '25', [$Url->a('Підключити', act=>'subscribe', product=>5)]);
        #Show Center $add_tbl->show;
    }
    else
    {
        my $result = decode_json($response->{'result'});
        #Show Center $response->{'result'};
        my $status = $result->{'status'};
        if ( !( $status == 200) )
        {
            Show Center $status;
            Error ( $result->{'message'} );
        }
        my $licence_keys = $result->{'keys'};
        #Show Center $licence_keys;
        my $keys_tbl = tbl->new( -class=>'pretty td_tall td_wide width100' );
        $keys_tbl->add('head', 'llllllll',
            'Ключ',
            'Назва',
            'Створено',
            'Пристроїв',
            'Стан',
            'Активацій',
            'Перiод',
            'Закінчення'
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
            $keys_tbl->add('*', 'llllllll',
                $lic_record->{'onlineKey'},
                $product_name,
                $lic_record->{'created'},
                $lic_record->{'devices'},
                $lic_record->{'licenceStatus'},
                $lic_record->{'activations'},
                $lic_record->{'period'},
                $lic_record->{'expired'},
                #$lic_record->{'description'},
                #[$Url->a('Скасувати передплату', act=>'disable', id=>$lic_record->{'id'})]
            );
        }
        Show Center $keys_tbl->show;
        Show Center 'Завантажте антивірусний продукт на <a href=https://zillya.ua/produkti-katalog-antivirusnikh-program-zillya>сайті Zillya.ua</a> та активуйте ліцензію отриманим ключем';
    }



}


1;
