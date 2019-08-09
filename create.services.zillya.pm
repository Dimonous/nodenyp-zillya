#<ACTION> file=>'services/zillya.pm',hook=>'new'
# ------------------- NoDeny ------------------
#  (с) Volik Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
# ------------------- Boryspil.net ------------
#  (с) Dmytro Vasyk (http://dmytrovasyk.com)
# ---------------------------------------------
package services::zillya;
use strict;
use Encode qw( decode_utf8 );
use JSON;
use Debug;
use nod::_zillya;

sub _tolog
{
    unshift @_, 'zillya api:';
    defined kernel::services->can('tolog') ? kernel::services::tolog(@_) : tolog(@_);
};

sub _decode
{
    return $_[0];
}


my $lang = {
    'RU' => {
        module_name         => 'Антивирус Zillya!',
        description         => '',
        mode                => 'Режим',
        mode_comment        => "<p id='period_mod_0'>Услуга действует с момента активации и завершается по прошествии времени, указанном в поле «Срок действия»".
                    "<p id='period_mod_1'>Длительность услуги меняется динамически от 28 до 31 дня в зависимости от количества дней в месяце. Если была подключена, например, 13 числа, то будет подключаться 13 числа каждого месяца".
                    "<p id='period_mod_2'>Услуга действует с момента активации до конца месяца. Т.е. всегда будет начинаться с 1 числа",
        period              => 'Срок действия',
        period_comment      => 'Например, `31 01:30:00` - 31 день, 1 час и 30 минут',
    },
    'UA' => {
        module_name         => 'Антивірус Zillya!',
        description         => '',
        mode                => 'Режим',
        mode_comment        => "<p id='period_mod_0'>Послуга діє з моменту активації і завершується після часу, зазначеному в поле «Термін дії»".
                    "<p id='period_mod_1'>Длительность услуги меняется динамически от 28 до 31 дня в зависимости от количества дней в месяце. Если была подключена, например, 13 числа, то будет подключаться 13 числа каждого месяца".
                    "<p id='period_mod_2'>Услуга действует с момента активации до конца месяца. Т.е. всегда будет начинаться с 1 числа",
        period              => 'Термін дії',
        period_comment      => 'Наприклад, `31 01:30:00` - 31 день, 1 година і 30 хвилин',
    },
};




sub name
{
    my(undef, $lang) = @_;
    $lang ||= 'RU';
    my $name = {
        'RU' => 'Антивирус Zillya!',
        'UA' => 'Антивірус Zillya!',
        'EN' => 'Antivirus Zillya!',
    };
    return $name->{$lang} || $name->{RU};
}

sub description
{
    my(undef, $lang) = @_;
    $lang ||= 'RU';
    my $name = {
        'RU' => <<DESCR,
       <a href='https://zillya.ua/ru'>https://zillya.ua/ru</a>
DESCR
        'UA' => <<DESCR,
       <a href='https://zillya.ua'>https://zillya.ua</a>
DESCR
        'EN' => 'Basic services',
    };
    return $name->{$lang} || $name->{RU};
}

sub tunes
{
    my(undef, $lang) = @_;
    my $l = {
        'RU' => {
            'tariff' =>   {
                title   => 'Тариф',
                type    => 'hash',
                hash    => {
                    1 => 'ZILLYA ANTIVIRUS V3',
                    2 => 'ZILLYA INTERNET SECURITY',
                    5 => 'ZILLYA TOTAL SECURITY',
                },
                comment => '',
                value   => '',
                css     => {
                    form => 'pretty',
                },
            },
            'multiple' => {
                title   => 'Multiple',
                comment => 'Клиент сможет подключить услугу, даже если уже подключена аналогичная из данного модуля',
            },
            'mode' => {
                title   => 'Режим',
                hash    => { '' => 'стандарт', 1 => 'месяц', 2 => 'конец месяца', 3 => 'без установки' },
                comment => "<p id='period_mod_0'>Услуга действует с момента активации и завершается по прошествии времени, указанном в поле «Срок действия»".
                    "<p id='period_mod_1'>Длительность услуги меняется динамически от 28 до 31 дня в зависимости от количества дней в месяце. Если была подключена, например, 13 числа, то будет подключаться 13 числа каждого месяца".
                    "<p id='period_mod_2'>Услуга действует с момента активации до конца месяца. Т.е. всегда будет начинаться с 1 числа",

            },
            'period' => {
                title   => 'Срок действия',
                comment => 'Например, `31 01:30:00` - 31 день, 1 час и 30 минут',
            },
            'tags' => {
                title   => 'Теги',
                comment => 'Через запятую. Заполнение не обязательно',
            },
        },
        'UA' => {
            'tariff' =>   {
                title   => 'Тариф',
                type    => 'hash',
                hash    => nod::zillya::get_base_tariffs(),
                comment => '',
                value   => '',
                css     => {
                    form => 'pretty',
                },
            },
            'multiple' => {
                title   => 'Multiple',
                comment => 'Клієнт може підключити послугу, навіть якщо вже підключена аналогічна з даного модуля',
            },
            'mode' => {
                title   => 'Режим',
                hash    => { '' => 'стандарт', 1 => 'місяць', 2 => 'кінець місяця', 3 => 'не встановлювати' },
                comment => "<p id='period_mod_0'>Послуга діє з моменту активації і завершується після часу, зазначеному в поле «Термін дії»".
                    "<p id='period_mod_1'>Длительность услуги меняется динамически от 28 до 31 дня в зависимости от количества дней в месяце. Если была подключена, например, 13 числа, то будет подключаться 13 числа каждого месяца".
                    "<p id='period_mod_2'>Услуга действует с момента активации до конца месяца. Т.е. всегда будет начинаться с 1 числа",

            },
            'period' => {
                title   => 'Термін дії',
                comment => 'Наприклад, `31 01:30:00` - 31 день, 1 година і 30 хвилин',
            },
            'tags' => {
                title   => 'Теги',
                comment => "Через кому. Заповнення не обов'язково",
            },
        },
    };
    my %l = %{$l->{$lang || 'RU'} || $l->{RU}};

    my $fields = [
    {
        name    => 'tariff',
        type    => 20,
        value   => 1,
        %{$l{tariff}},
    },
    {
        name    => 'multiple',
        type    => 6,
        value   => 1,
        %{$l{multiple}},
    },
    {
        name    => 'mode',
        type    => 20,
        %{$l{mode}},
    },
    {
        name    => 'period',
        type    => 11,
        value   => 30*24*3600,
        %{$l{period}},
    },
    {
        name    => 'tags',
        type    => 4,
        value   => '',
        %{$l{tags}},
    },
    ];

    return $fields;
}

sub add_html
{
    return 'service_type_select';
}

sub set_service
{
    my(undef, %p) = @_;
    my $uid         = $p{uid};
    my $service_new = $p{service_new};
    my $service_old = $p{service_old};
    my $actions     = $p{actions};

    my $tags = ','.$service_new->{param}{tags}.',';
    $tags =~ s| ||g;
    my $balance_field;
    if( $tags =~ /,(_balance[^,]+),/ )
    {
        $balance_field = $1;
        $actions->{sql}{reduce_virtual_balance} = [
            "UPDATE data0 SET $balance_field = CAST(($balance_field - ?) AS DECIMAL(10,2)) WHERE uid=?",
            $service_new->{price}, $uid
        ];
        my $reason = {
            from => $balance_field,
            to => 'balance',
            from_title => $balance_field,
            to_title => 'balance',
            amount => $service_new->{price},
        };
        $actions->{sql}{from_virtual_to_real_balance} = [
            "INSERT INTO pays SET category=31, creator_ip=0, creator='kernel', creator_id=1, time=UNIX_TIMESTAMP(), ".
            "mid=?, cash=?, reason=?",
            $uid, $service_new->{price}, Debug->dump($reason)
        ];
        $actions->{pay} ||= {};
        $actions->{pay}{do_not_change_balance} = 1;
    }
    if( $service_new->{param}{mode} != 3 )
    {
        $actions->{set_service} = {
            period => int $service_new->{param}{period},
            mode   => int $service_new->{param}{mode},
            tags   => $tags,
        };
        $actions->{set_service}{to_reason}{virtual_balance} = $balance_field if $balance_field;
    }

    my $price = $service_new->{price};
    if( $price != 0 )
    {
        $actions->{pay} ||= {};
        $actions->{pay}{cash} = 0 - $price;
        $actions->{pay}{comment} = $service_new->{description} || $service_new->{title};
        $actions->{pay}{category} = $price>0? 100 : 50;
        $actions->{pay}{discount} = $service_new->{discount};
    }


    my $response = nod::zillya::api_request('get_licences_for_uid', $uid);
    if (exists($response->{'error'}))
    {
        my $status = $response->{'code'};
        if ( !($status == 404) )
        {
            _tolog $response->{'error'} ;
        }
        #'Передплата на послугу відсутня:'
        $response = nod::zillya::api_request('add_licence', $uid, $service_new->{param}{tariff}, $service_new->{param}{period}/60/60/24 );
        debug 'info', $response;
    }
    else
    {
        debug 'info', $service_new;
        my $result = decode_json($response->{'result'});
        my $status = $result->{'status'};
        if ( !( $status == 200) )
        {
            _tolog $result->{'message'} ;
        }
        my $licence_keys = $result->{'keys'};
        for my $lic_record ( @$licence_keys )
        {
            my $product     = $lic_record->{'product'};
            my $crated      = $lic_record->{'created'};
            my $devices     = $lic_record->{'devices'};
            my $expired     = $lic_record->{'expired'};
            my $status      = $lic_record->{'licenceStatus'};
            my $activations = $lic_record->{'activations'};
            my $period = $lic_record->{'period'};
            my $new_period = $period + $service_new->{param}{period}/60/60/24;
            debug 'info', $new_period;
            if ($product == $service_new->{param}{tariff})
            {
                #продление
                $response = nod::zillya::api_request('prolong_licenсe', $lic_record->{'id'}, $new_period );
                debug 'info', $response;
            } else {
                #новая лицензия
                $response = nod::zillya::api_request('add_licence', $uid, $product, $new_period );
                debug 'info', $response;
            }

        }
    }

}


sub end_service
{
    my(undef, %p) = @_;
    my $uid = $p{uid};
    my $service = $p{service};
    my $actions = $p{actions};
    my $pay     = $p{pay};

    my $response = nod::zillya::api_request('get_licences_for_uid', $uid);
    debug 'info', $response;
    if (!exists($response->{'error'}))
    {
        my $result = decode_json($response->{'result'});
        my $status = $result->{'status'};
        if  ( $status == 200)
        {
            my $licence_keys = $result->{'keys'};
            for my $lic_record ( @$licence_keys )
            {
                my $product     = $lic_record->{'product'};
                if ($product == $service->{param}{tariff})
                {
                    $response = nod::zillya::api_request('disable_licence', $lic_record->{'id'} );
                    debug 'info', $response;
                }
            }
        }
    }

}

1;
