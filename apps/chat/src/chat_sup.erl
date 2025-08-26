-module(chat_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

-type ip() :: {integer(), integer(), integer(), integer()}.
-type cowboy_port() :: integer().

%% API functions
-spec start_link() ->
    {ok, pid()}.

start_link() ->
    supervisor:start_link(?MODULE, []).

%% Supervisor callbacks

-spec init([]) ->
    {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.

init([]) ->
    ExtPort = 8080,
    {ok, {#{strategy => one_for_all}, [get_cowboy_child_spec({0, 0, 0, 0}, ExtPort), #{
        id       => server,
        start    => {chat_server, start_link, []},
        restart  => transient,
        shutdown => infinity,
        type     => worker,
        modules  => [chat_server]},
    #{
        id       => bot,
        start    => {bot_server, start_link, []},
        restart  => permanent,
        shutdown => infinity,
        type     => worker,
        modules  => [bot_server]}
    ]}}.

-spec get_cowboy_child_spec(ip(), cowboy_port()) ->
    supervisor:child_spec().

get_cowboy_child_spec(IP, Port) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/", cowboy_static, {priv_file, chat, "index.html"}},
            {"/websocket", web_handler, []},
            {"/static/[...]", cowboy_static, {priv_dir, chat, "static"}}
        ]}
    ]),
    ranch:child_spec(
        ?SERVER,
        ranch_tcp,
        [
            {ip, IP},
            {port, Port},
            {num_acceptors, 4}
        ],
        cowboy_clear,
        #{
            env => #{dispatch => Dispatch}
        }
    ).
