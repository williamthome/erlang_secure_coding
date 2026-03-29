-module(esc_home_view).
-include_lib("arizona/include/arizona_stateful.hrl").
-export([mount/1, render/1]).
-export([render_module_card/1]).

mount(Bindings0) ->
    Modules = esc_curriculum:modules(),
    Bindings = maps:merge(#{id => ~"home", modules => Modules}, Bindings0),
    {Bindings, #{}}.

render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            {'div', [{class, ~"mb-8"}], [
                {h1, [{class, ~"text-3xl font-bold text-gray-900 mb-2"}], ~"Security Curriculum"},
                {p, [{class, ~"text-gray-600"}],
                    ~"Learn to write secure Erlang/OTP applications through interactive lessons and quizzes."}
            ]},
            {'div', [{class, ~"grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"}], [
                ?each(
                    fun(Module) ->
                        ?stateless(render_module_card, Module)
                    end,
                    ?get(modules)
                )
            ]}
        ]}
    ).

render_module_card(Props) ->
    MId = maps:get(id, Props),
    Num = maps:get(number, Props),
    Title = maps:get(title, Props),
    Desc = maps:get(description, Props),
    Mins = maps:get(estimated_minutes, Props),
    ?html(
        {a,
            [
                {href, <<"/modules/", MId/binary>>},
                az_navigate,
                {class,
                    ~"block bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md hover:border-indigo-300 transition-all"}
            ],
            [
                {'div', [{class, ~"flex items-center gap-3 mb-3"}], [
                    {span,
                        [{class,
                            ~"bg-indigo-100 text-indigo-700 text-sm font-semibold px-2.5 py-0.5 rounded"}],
                        [~"Module ", Num]},
                    {span, [{class, ~"text-gray-400 text-sm"}], [Mins, ~" min"]}
                ]},
                {h2, [{class, ~"text-lg font-semibold text-gray-900 mb-2"}], Title},
                {p, [{class, ~"text-gray-600 text-sm"}], Desc}
            ]}
    ).
