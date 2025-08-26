-module(bot_server).

-behaviour(gen_server).

-export([init/1, stop/0, start_link/0, handle_cast/2, handle_call/3, terminate/2]).
-export([loop/0]).
-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).

init(_) ->
    spawn_link(?SERVER, loop, []),
    {ok, {}}.

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

stop() ->
    gen_server:cast(?SERVER, stop).

gen_random_string() -> <<"test">>.