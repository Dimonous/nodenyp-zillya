#<ACTION> file=>'nod/zillya.pm',hook=>'new'
# ------------------- NoDeny ------------------
#  (с) Volik Stanislav (http://nodeny.com.ua)
# ---------------------------------------------
# ------------------- Boryspil.net ------------
#  (с) Dmytro Vasyk (http://dmytrovasyk.com)
# ---------------------------------------------
package nod::zillya;
use strict;
use LWP::UserAgent;
use Digest::SHA qw( hmac_sha256_hex );
use JSON;
use Debug;
use Data::Dumper qw(Dumper);
use DateTime;
use DateTime::Duration;

# https://metacpan.org/pod/HTTP::Response


my $api_err_msg = 'API Zillya вернуло ошибку, смотрите debug';

sub get_base_tariffs
{
    return {
        1 => 'ZILLYA ANTIVIRUS V3',
        2 => 'ZILLYA INTERNET SECURITY',
        5 => 'ZILLYA TOTAL SECURITY',
    };
}


sub api_request
{
    my($action, @context) = @_;
    debug 'info', $action;
    debug 'info', @context;
    my $uid = $context[0];
    my $licence_id = $context[1];
    my $period = $context[2];
    #my($action, $uid, $licence_id, $period ) = @_;

    my $param = {
        api_url     => $cfg::zillya_url || 'http://kernel.zillyaantivirus.com/api/v1',
        api_user    => $cfg::zillya_username,
        api_pass    => $cfg::zillya_pass
    };

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my %request_params;
    $request_params{apiUser}{username} = $param->{api_user};
    $request_params{apiUser}{pass} = $param->{api_pass};
    my $content = encode_json  \%request_params;

    #Show Center 'Производим запрос авторизации к API..';
    # Show Center '-'.$api_url.'-';
    my $response = $ua->post( $param->{api_url}, Content => $content );
    if (!$response->is_success) {
        return { error => $response->status_line } ;
    }
    my $respHash = decode_json($response->decoded_content);
    my $token = $respHash->{apiUser}{token};
    #Show Center 'Токен авторизации успешно получен';

    %request_params = ();
    $request_params{apiUser}{token} = $token;

    if ($action eq 'get_keys') {
        $request_params{action}{do} = 'getKeys';
        $request_params{recepientURL} = 'direct';
        $request_params{action}{type} = 'active';
    }  elsif ($action eq 'get_licences_for_uid') {
        $request_params{action}{do} = 'getKeys';
        $request_params{recepientURL} = 'direct';
        $request_params{action}{filter}{userMail} = $context[0];
        $request_params{action}{type} = 'active';
    } elsif ($action eq 'disable_licence') {
        $request_params{action}{do} = 'modifyKey';
        $request_params{recepientURL} = 'direct';
        $request_params{action}{modifier} = 'licenceStatus';
        $request_params{action}{set} = 'blocked';
        $request_params{action}{filter}{licenceId} = $context[0];
    } elsif ($action eq 'generate_test_key') {
        $request_params{action}{do} = 'generateKey';
        $request_params{action}{keyInformation}{quantity} = 1;
        $request_params{action}{keyInformation}{brand} = 5;
        $request_params{action}{keyInformation}{product} = 1;
        $request_params{action}{keyInformation}{description} = '5004';
        $request_params{action}{keyInformation}{devices} = 1;
        $request_params{action}{keyInformation}{period} = $period;
        $request_params{recepientURL} = 'direct';
    } elsif ($action eq 'prolong_licenсe') {
        $request_params{action}{do} = 'modifyKey';
        $request_params{action}{modifier} = 'period';
        $request_params{action}{set} = $context[1];
        $request_params{action}{filter}{licenceId} = $context[0];
    } elsif ($action eq 'enable_licence') {
        $request_params{action}{do} = 'modifyKey';
        $request_params{recepientURL} = 'direct';
        $request_params{action}{modifier} = 'licenceStatus';
        $request_params{action}{set} = 'active';
        $request_params{action}{filter}{licenceId} = $context[0];
    } elsif ($action eq 'add_licence') {
        my $brand;
        my $product = $context[1];
        if ($product == 1) {
            $brand = 5;
        } elsif ($product == 2) {
            $brand = 6;
        } elsif ($product == 5) {
            $brand = 24;
        } else {
            return { error => 'Помилковий Product ID', code => 400 };
        }
        $request_params{action}{do} = 'generateKey';
        $request_params{action}{keyInformation}{quantity} = 1;
        $request_params{action}{keyInformation}{brand} = $brand;
        $request_params{action}{keyInformation}{product} = $product;
        $request_params{action}{keyInformation}{description} = $context[0];
        $request_params{action}{keyInformation}{devices} = 1;
        $request_params{action}{keyInformation}{period} = $context[2];
        $request_params{recepientURL} = 'direct';
    } else {
        return { error => 'Помилковий виклик API', code => 400 };
    }

    debug 'info', \%request_params;
    my $request_content = encode_json  \%request_params;
    $response = $ua->post( $param->{api_url}, Content => $request_content );
    if (!$response->is_success) {
        return { error => $response->status_line, code => $response->code, $content => $response->content, response => $response, result => $response->decoded_content, context => $request_content, action => $action, uid => $uid };
    }
    return { result => $response->decoded_content, context => $request_content };

}

1;
