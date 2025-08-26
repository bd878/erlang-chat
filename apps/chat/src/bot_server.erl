-module(bot_server).

-behaviour(gen_server).

-export([init/1]).
-export([stop/0]).
-export([start_link/0]).
-export([handle_cast/2]).
-export([handle_call/3]).
-export([terminate/2]).
-export([loop/0]).

-define(SERVER, ?MODULE).

%%% CALLBACKS
-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).

-spec init(term()) -> {ok, {}}.
init(_) ->
    spawn_link(?SERVER, loop, []),
    {ok, {}}.

-spec loop() -> no_return().
loop() ->
    timer:send_after(rand:uniform(10000), self(), {message, gen_random_string()}),
    receive
        {message, Message} ->
            chat_server:send_message(self(), Message),
            loop();
        Reason -> exit(Reason)
    end.

handle_cast(_, State) ->
    {noreply, State}.

handle_call(_, _, _) -> ok.

terminate(_, _) -> ok.

stop() -> gen_server:cast(?SERVER, stop).

%%% PRIVATE
-spec gen_random_string() -> binary().
gen_random_string() -> <<"test">>.