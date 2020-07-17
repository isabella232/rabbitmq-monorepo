%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2020 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(rabbit_stomp_sup).
-behaviour(supervisor).

-export([start_link/2, init/1]).

start_link(Listeners, Configuration) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE,
                          [Listeners, Configuration]).

init([{Listeners, SslListeners0}, Configuration]) ->
    NumTcpAcceptors = application:get_env(rabbitmq_stomp, num_tcp_acceptors, 10),
    {ok, SocketOpts} = application:get_env(rabbitmq_stomp, tcp_listen_options),
    {SslOpts, NumSslAcceptors, SslListeners}
        = case SslListeners0 of
              [] -> {none, 0, []};
              _  -> {rabbit_networking:ensure_ssl(),
                     application:get_env(rabbitmq_stomp, num_ssl_acceptors, 10),
                     case rabbit_networking:poodle_check('STOMP') of
                         ok     -> SslListeners0;
                         danger -> []
                     end}
          end,
    Flags = #{
        strategy => one_for_all,
        period => 10,
        intensity => 10
    },
    {ok, {Flags,
           listener_specs(fun tcp_listener_spec/1,
                          [SocketOpts, Configuration, NumTcpAcceptors], Listeners) ++
           listener_specs(fun ssl_listener_spec/1,
                          [SocketOpts, SslOpts, Configuration, NumSslAcceptors], SslListeners)}}.

listener_specs(Fun, Args, Listeners) ->
    [Fun([Address | Args]) ||
        Listener <- Listeners,
        Address  <- rabbit_networking:tcp_listener_addresses(Listener)].

tcp_listener_spec([Address, SocketOpts, Configuration, NumAcceptors]) ->
    rabbit_networking:tcp_listener_spec(
      rabbit_stomp_listener_sup, Address, SocketOpts,
      transport(stomp), rabbit_stomp_client_sup, Configuration,
      stomp, NumAcceptors, "STOMP TCP listener").

ssl_listener_spec([Address, SocketOpts, SslOpts, Configuration, NumAcceptors]) ->
    rabbit_networking:tcp_listener_spec(
      rabbit_stomp_listener_sup, Address, SocketOpts ++ SslOpts,
      transport('stomp/ssl'), rabbit_stomp_client_sup, Configuration,
      'stomp/ssl', NumAcceptors, "STOMP TLS listener").

transport(Protocol) ->
    case Protocol of
        stomp       -> ranch_tcp;
        'stomp/ssl' -> ranch_ssl
    end.
