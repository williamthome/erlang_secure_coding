-module(esc_module_view).
-include_lib("arizona/include/arizona_stateful.hrl").
-export([mount/1, render/1, handle_event/3]).
-export([
    render_module_content/1,
    render_nav_buttons/1,
    render_quiz/1,
    render_score_banner/1,
    render_submit_button/1
]).

mount(Bindings0) ->
    ModuleId = maps:get(module_id, Bindings0, undefined),
    Module =
        case esc_curriculum:get_module(ModuleId) of
            {ok, M} -> M;
            error -> not_found
        end,
    Bindings = maps:merge(
        #{
            id => ~"module-view",
            module => Module,
            current_section => 0,
            quiz_answers => #{},
            quiz_results => #{},
            quiz_submitted => false,
            show_explanations => #{}
        },
        Bindings0
    ),
    {Bindings, #{}}.

render(Bindings) ->
    ?html(
        {'div', [{id, ?get(id)}], [
            case ?get(module) of
                not_found ->
                    ?html(
                        {'div', [{class, ~"text-center py-16"}], [
                            {h1, [{class, ~"text-2xl font-bold text-gray-900 mb-4"}],
                                ~"Module Not Found"},
                            {a,
                                [
                                    {href, ~"/"},
                                    az_navigate,
                                    {class, ~"text-indigo-600 hover:underline"}
                                ],
                                ~"Back to curriculum"}
                        ]}
                    );
                _ ->
                    ?stateless(render_module_content, #{
                        id => ?get(id),
                        module => ?get(module),
                        current_section => ?get(current_section),
                        quiz_answers => ?get(quiz_answers),
                        quiz_results => ?get(quiz_results),
                        quiz_submitted => ?get(quiz_submitted),
                        show_explanations => ?get(show_explanations)
                    })
            end
        ]}
    ).

render_module_content(Props) ->
    Module = maps:get(module, Props),
    #{title := Title, number := Num, estimated_minutes := Mins, sections := Sections} = Module,
    CurrentIdx = maps:get(current_section, Props),
    Section = lists:nth(CurrentIdx + 1, Sections),
    #{title := STitle, content := SContent} = Section,
    CodeExamples = maps:get(code_examples, Section, []),
    ?html(
        {'div', [], [
            {'div', [{class, ~"mb-6"}], [
                {a,
                    [
                        {href, ~"/"},
                        az_navigate,
                        {class, ~"text-indigo-600 hover:underline text-sm"}
                    ],
                    ~"<- Back to curriculum"}
            ]},
            {'div', [{class, ~"mb-8"}], [
                {'div', [{class, ~"flex items-center gap-3 mb-2"}], [
                    {span,
                        [
                            {class,
                                ~"bg-indigo-100 text-indigo-700 text-sm font-semibold px-2.5 py-0.5 rounded"}
                        ],
                        [~"Module ", Num]},
                    {span, [{class, ~"text-gray-400 text-sm"}], [Mins, ~" min"]}
                ]},
                {h1, [{class, ~"text-3xl font-bold text-gray-900"}], Title}
            ]},
            {'div', [{class, ~"bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-8"}], [
                {h2, [{class, ~"text-2xl font-semibold text-gray-900 mb-4"}], STitle},
                {'div', [{class, ~"prose prose-gray max-w-none mb-6"}], SContent},
                ?each(
                    fun(Example) ->
                        render_code_example(Example)
                    end,
                    CodeExamples
                )
            ]},
            ?stateless(render_nav_buttons, #{
                current_section => CurrentIdx,
                total_sections => length(Sections)
            }),
            ?stateless(render_quiz, #{
                quiz => maps:get(quiz, Module),
                quiz_answers => maps:get(quiz_answers, Props),
                quiz_results => maps:get(quiz_results, Props),
                quiz_submitted => maps:get(quiz_submitted, Props),
                show_explanations => maps:get(show_explanations, Props)
            })
        ]}
    ).

render_code_example(#{title := ETitle, code := Code, explanation := Expl} = Example) ->
    IsVuln = maps:get(vulnerable, Example, false),
    Output = maps:get(output, Example, ~""),
    BorderClass = vuln_border_class(IsVuln),
    HeaderClass = vuln_header_class(IsVuln),
    TextClass = vuln_text_class(IsVuln),
    Label = vuln_label(IsVuln),
    ?html(
        {'div', [{class, [~"my-6 rounded-lg border ", BorderClass]}], [
            {'div', [{class, [~"px-4 py-2 border-b ", HeaderClass, ~" flex items-center gap-2"]}], [
                    {span, [{class, [~"text-sm font-medium ", TextClass]}], Label},
                    {span, [{class, ~"text-sm text-gray-600"}], ETitle}
                ]},
            {pre, [{class, ~"p-4 overflow-x-auto"}], [
                {code, [{class, ~"language-erlang text-sm"}], Code}
            ]},
            case Output of
                ~"" ->
                    ~"";
                _ ->
                    ?html(
                        {'div', [{class, ~"px-4 py-2 border-t border-gray-200 bg-gray-50"}], [
                            {span, [{class, ~"text-xs text-gray-500 font-medium"}], ~"Output:"},
                            {pre, [{class, ~"text-sm text-gray-700 mt-1"}], Output}
                        ]}
                    )
            end,
            {'div', [{class, [~"px-4 py-3 border-t ", BorderClass]}], [
                {p, [{class, ~"text-sm text-gray-700"}], Expl}
            ]}
        ]}
    ).

render_nav_buttons(Props) ->
    CurrentIdx = maps:get(current_section, Props),
    TotalSections = maps:get(total_sections, Props),
    PrevClass =
        case CurrentIdx of
            0 -> ~"px-4 py-2 bg-gray-200 text-gray-700 rounded opacity-50 cursor-not-allowed";
            _ -> ~"px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
        end,
    ?html(
        {'div', [{class, ~"flex items-center justify-between mb-8"}], [
            {button, [{az_click, arizona_js:push_event(~"prev_section")}, {class, PrevClass}],
                ~"<- Previous"},
            {span, [{class, ~"text-gray-500 text-sm"}], [
                ~"Section ", CurrentIdx + 1, ~" of ", TotalSections
            ]},
            case CurrentIdx < TotalSections - 1 of
                true ->
                    ?html(
                        {button,
                            [
                                {az_click, arizona_js:push_event(~"next_section")},
                                {class,
                                    ~"px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"}
                            ],
                            ~"Next ->"}
                    );
                false ->
                    ?html(
                        {span,
                            [
                                {class,
                                    ~"px-4 py-2 bg-green-100 text-green-700 rounded text-sm font-medium"}
                            ],
                            ~"All sections complete!"}
                    )
            end
        ]}
    ).

render_quiz(Props) ->
    Quiz = maps:get(quiz, Props),
    QuizSubmitted = maps:get(quiz_submitted, Props),
    QuizAnswers = maps:get(quiz_answers, Props),
    QuizResults = maps:get(quiz_results, Props),
    ShowExplanations = maps:get(show_explanations, Props),
    ?html(
        {'div', [{class, ~"bg-white rounded-lg shadow-sm border border-gray-200 p-8"}], [
            {h2, [{class, ~"text-2xl font-semibold text-gray-900 mb-2"}], ~"Knowledge Check"},
            {p, [{class, ~"text-gray-600 mb-6"}],
                ~"Test your understanding of this module's concepts."},
            case QuizSubmitted of
                true -> ?stateless(render_score_banner, #{quiz_results => QuizResults});
                false -> ~""
            end,
            ?each(
                fun(#{id := QId, prompt := Prompt, options := Options}) ->
                    render_question(
                        QId,
                        Prompt,
                        Options,
                        QuizAnswers,
                        QuizResults,
                        QuizSubmitted,
                        ShowExplanations
                    )
                end,
                Quiz
            ),
            case QuizSubmitted of
                false -> ?stateless(render_submit_button, #{});
                true -> ~""
            end
        ]}
    ).

render_score_banner(Props) ->
    QuizResults = maps:get(quiz_results, Props),
    #{correct := C, total := T} = esc_quiz_grader:score(QuizResults),
    {BannerClass, TextClass} =
        case C =:= T of
            true ->
                {
                    ~"mb-6 p-4 rounded-lg bg-green-50 border border-green-200",
                    ~"font-semibold text-green-700"
                };
            false ->
                {
                    ~"mb-6 p-4 rounded-lg bg-yellow-50 border border-yellow-200",
                    ~"font-semibold text-yellow-700"
                }
        end,
    Suffix =
        case C =:= T of
            true -> ~" -- Perfect!";
            false -> ~""
        end,
    ?html(
        {'div', [{class, BannerClass}], [
            {p, [{class, TextClass}], [~"Score: ", C, ~" / ", T, Suffix]}
        ]}
    ).

render_submit_button(_Props) ->
    ?html(
        {button,
            [
                {az_click, arizona_js:push_event(~"submit_quiz")},
                {class,
                    ~"mt-6 px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium"}
            ],
            ~"Submit Answers"}
    ).

handle_event(~"next_section", _Params, Bindings) ->
    Current = maps:get(current_section, Bindings),
    #{sections := Sections} = maps:get(module, Bindings),
    Next = min(Current + 1, length(Sections) - 1),
    {Bindings#{current_section => Next}, #{}, []};
handle_event(~"prev_section", _Params, Bindings) ->
    Current = maps:get(current_section, Bindings),
    Prev = max(Current - 1, 0),
    {Bindings#{current_section => Prev}, #{}, []};
handle_event(~"select_answer", #{~"question_id" := QId, ~"answer_id" := AId}, Bindings) ->
    Answers = maps:get(quiz_answers, Bindings),
    {Bindings#{quiz_answers => Answers#{QId => AId}}, #{}, []};
handle_event(~"submit_quiz", _Params, Bindings) ->
    #{id := ModuleId} = maps:get(module, Bindings),
    Answers = maps:get(quiz_answers, Bindings),
    Results = esc_quiz_grader:grade_quiz(ModuleId, Answers),
    {Bindings#{quiz_results => Results, quiz_submitted => true}, #{}, []};
handle_event(~"show_explanation", #{~"question_id" := QId}, Bindings) ->
    Shown = maps:get(show_explanations, Bindings),
    {Bindings#{show_explanations => Shown#{QId => true}}, #{}, []}.

%% Internal

render_question(QId, Prompt, Options, Answers, Results, Submitted, ShowExplanations) ->
    SelectedAnswer = maps:get(QId, Answers, undefined),
    Result = maps:get(QId, Results, undefined),
    ShowExpl = maps:get(QId, ShowExplanations, false),
    ?html(
        {'div', [{class, ~"mb-6 p-4 rounded-lg border border-gray-200"}], [
            {p, [{class, ~"font-medium text-gray-900 mb-3"}], Prompt},
            {'div', [{class, ~"space-y-2"}], [
                ?each(
                    fun(#{id := OId, text := OText}) ->
                        render_option(QId, OId, OText, SelectedAnswer, Submitted, Result)
                    end,
                    Options
                )
            ]},
            render_explanation(Submitted, Result, ShowExpl, QId)
        ]}
    ).

render_option(QId, OId, OText, SelectedAnswer, Submitted, Result) ->
    IsSelected = SelectedAnswer =:= OId,
    BaseClass =
        case IsSelected of
            true -> ~"border-indigo-300 bg-indigo-50";
            false -> ~"border-gray-100 hover:bg-gray-50"
        end,
    ResultClass =
        case {Submitted, Result, IsSelected} of
            {true, #{correct := true}, true} -> ~" border-green-300 bg-green-50";
            {true, #{correct := false}, true} -> ~" border-red-300 bg-red-50";
            _ -> ~""
        end,
    ?html(
        {label,
            [
                {class, [
                    ~"flex items-center gap-3 p-3 rounded-lg cursor-pointer border transition-all ",
                    BaseClass,
                    ResultClass
                ]}
            ],
            [
                {input, [
                    {type, ~"radio"},
                    {name, [~"q_", QId]},
                    {value, OId},
                    {checked, IsSelected},
                    {class, ~"text-indigo-600"},
                    {az_click,
                        arizona_js:push_event(
                            ~"select_answer",
                            #{~"question_id" => QId, ~"answer_id" => OId}
                        )}
                ]},
                {span, [{class, ~"text-gray-700"}], OText}
            ]}
    ).

render_explanation(true, #{explanation := Expl}, true, _QId) ->
    ?html(
        {'div', [{class, ~"mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg"}], [
            {p, [{class, ~"text-sm text-blue-800"}], Expl}
        ]}
    );
render_explanation(true, Result, false, QId) when Result =/= undefined ->
    ?html(
        {button,
            [
                {az_click,
                    arizona_js:push_event(
                        ~"show_explanation",
                        #{~"question_id" => QId}
                    )},
                {class, ~"mt-3 text-sm text-indigo-600 hover:underline"}
            ],
            ~"Show explanation"}
    );
render_explanation(_, _, _, _) ->
    ~"".

vuln_border_class(true) -> ~"border-red-200 bg-red-50";
vuln_border_class(false) -> ~"border-green-200 bg-green-50".

vuln_header_class(true) -> ~"border-red-200 bg-red-100";
vuln_header_class(false) -> ~"border-green-200 bg-green-100".

vuln_text_class(true) -> ~"text-red-700";
vuln_text_class(false) -> ~"text-green-700".

vuln_label(true) -> ~"&#x26A0; Vulnerable";
vuln_label(false) -> ~"&#x2713; Safe".
