-module(chat_server).

-behaviour(gen_server).

-export([init/1]).
-export([handle_cast/2]).
-export([terminate/2]).
-export([handle_call/3]).
-export([start_link/0]).
-export([stop/0]).
-export([add_client/1]).
-export([remove_client/1]).
-export([send_message/2]).

-define(SERVER, ?MODULE).

-record(state, {
    clients = [] :: [pid()]
}).

-type command() :: add_client | remove_client | send_message.

%%% INTERFACE
-spec add_client(pid()) -> term().
add_client(Pid) ->
    gen_server:call(?SERVER, {add_client, Pid}).

-spec remove_client(pid()) -> term().
remove_client(Pid) ->
    gen_server:call(?SERVER, {remove_client, Pid}).

-spec send_message(pid(), binary()) -> term().
send_message(Pid, Message) ->
    gen_server:call(?SERVER, {send_message, {Pid, Message}}).

%%% CALLBACKS
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).

-spec init(term()) -> {ok, #state{}}.
init(_) -> {ok, #state{clients=[]}}.

-spec handle_call({command(), pid() | {pid(), binary()}}, pid(), #state{}) -> {reply, ok, #state{}}.
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

handle_cast(_, State) -> {noreply, State}.

terminate(_, _) -> ok.

stop() -> gen_server:cast(?SERVER, stop).
