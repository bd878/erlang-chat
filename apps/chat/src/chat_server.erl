-module(chat_server).

-behaviour(gen_server).

-export([init/1, handle_call/3, start_link/0, stop/0, handle_cast/2, terminate/2]).
-export([add_client/1, remove_client/1, send_message/2]).

-define(SERVER, ?MODULE).

-record(state, {clients=[]}).

%%% INTERFACE
add_client(Pid) ->
    gen_server:call(?SERVER, {add_client, Pid}).

remove_client(Pid) ->
    gen_server:call(?SERVER, {remove_client, Pid}).

send_message(Pid, Message) ->
    gen_server:call(?SERVER, {send_message, {Pid, Message}}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).

init(_) ->
    {ok, #state{clients=[]}}.

handle_call({add_client, Me}, _, S = #state{clients=Clients}) ->
    logger:alert("new client pid - ~p", [Me]),
    NextClients = [Me|Clients],
    [Pid ! {clients, NextClients} || Pid <- NextClients],
    {reply, ok, S#state{clients=NextClients}};

handle_call({remove_client, Me}, _, S = #state{clients=Clients}) ->
    logger:alert("client left - ~p", [Me]),
    NextClients = lists:delete(Me, Clients),
    [Pid ! {clients, NextClients} || Pid <- NextClients],
    {reply, ok, S#state{clients=NextClients}};

handle_call({send_message, {Me, Message}}, _, S = #state{clients=Clients}) ->
    logger:alert("send message - ~p", [{Me, Message}]),
    [Pid ! {message, Message} || Pid <- Clients, Pid =/= Me],
    {reply, ok, S}.

handle_cast(_, State) ->
    {noreply, State}.

terminate(_, _) ->
    ok.

stop() ->
    gen_server:cast(?SERVER, stop).
