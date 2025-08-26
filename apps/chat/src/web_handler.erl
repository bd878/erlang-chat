-module(web_handler).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

-type state() :: #{}.

-spec init(_, _) -> {cowboy_websocket, _, _, _}.

init(Req, Opts) ->
    {cowboy_websocket, Req, Opts, #{
        idle_timeout => 60000}}.

-spec websocket_init(term()) -> {ok, state()}.

websocket_init(_) ->
    logger:alert("websocket_init ..."),
    chat_server:add_client(self()),
    {ok, #{}}.

-spec websocket_handle(_, state()) -> {reply, _, state()} | {ok, state()}.

websocket_handle({text, Text}, State) ->
    #{<<"type">> := Type, <<"data">> := Data} = jsx:decode(Text, [return_maps]),
    logger:alert("Handle message - ~p", [{self(), Type, Data}]),
    {Reply, NewState} = case {Type, Data} of
        {<<"send_message">>, Message} ->
            chat_server:send_message(self(), Message),
            {{new_message, Message}, State};
        Unknown ->
            logger:alert("get unknown message - ~p", [{self(), Unknown}]),
            {disconnect, State}
    end,
    {reply, {text, encode(Reply)}, NewState};
websocket_handle(_Data, State) ->
    logger:alert("get unknown message - ~p", [_Data]),
    {ok, State}.

terminate(_, _, _) ->
    logger:alert("terminate ws connection - ~p", [self()]),
    chat_server:remove_client(self()),
    ok.

-spec websocket_info(_, state()) -> {reply, _, state()} | {ok, state()}.

% get message
websocket_info({'DOWN', _Ref, process, _Pid, Reason}, State) ->
    logger:alert("server down with reason - ~p", [Reason]),
    {reply, {text, encode({service_message, <<"Server down">>})}, State};

websocket_info({message, Message}, State) ->
    logger:alert("send message - ~p", [Message]),
    {reply, {text, encode({new_message, Message})}, State};

websocket_info(Info, State) ->
    logger:alert("Get unexpected info - ~p", [Info]),
    {ok, State}.

encode({Type, Data}) ->
    jsx:encode(#{type => Type, data => Data}).
