-module(amqp10_client_sup).

-behaviour(supervisor).

%% Private API.
-export([start_link/0]).

%% Supervisor callbacks.
-export([init/1]).

-define(CHILD(Id, Mod, Type, Args), {Id, {Mod, start_link, Args},
                                     temporary, infinity, Type, [Mod]}).

%% -------------------------------------------------------------------
%% Private API.
%% -------------------------------------------------------------------

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% -------------------------------------------------------------------
%% Supervisor callbacks.
%% -------------------------------------------------------------------

init([]) ->
    Template = ?CHILD(connection_sup, amqp10_client_connection_sup,
                      supervisor, []),
    {ok, {{simple_one_for_one, 0, 1}, [Template]}}.