-module(erlang_secure_coding_router).
-behaviour(nova_router).

-export([routes/1]).

routes(_Environment) ->
    Layout = {esc_layout, render},
    LiveReload = application:get_env(arizona_nova, live_reload, false),
    [
        #{
            prefix => "",
            security => false,
            routes => [
                arizona_nova_live:route("/", esc_home_view, #{layout => Layout}),
                arizona_nova_live:route("/modules/:module_id", esc_module_view, #{layout => Layout}),
                {"/ws", arizona_nova_ws, #{protocol => ws}},
                {"/assets/[...]", "static/assets"},
                {"/arizona/:file", fun arizona_nova_static:serve_js/1, #{methods => [get]}}
            ] ++ case LiveReload of
                true -> [{"/arizona/reload", fun arizona_nova_reload:handle/1, #{methods => [get]}}];
                false -> []
            end
        }
    ].
