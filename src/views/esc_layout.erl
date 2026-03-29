-module(esc_layout).
-include_lib("arizona/include/arizona_stateless.hrl").
-export([render/1]).

render(Bindings) ->
    ?html([
        ~"<!DOCTYPE html>",
        {html, [{lang, ~"en"}, az_nodiff], [
            {head, [], [
                {meta, [{charset, ~"UTF-8"}]},
                {meta, [{name, ~"viewport"}, {content, ~"width=device-width, initial-scale=1.0"}]},
                {title, [], ~"Erlang Secure Coding"},
                {script, [{src, ~"https://cdn.tailwindcss.com"}], []},
                {link, [{rel, ~"stylesheet"}, {href, ~"/assets/css/app.css"}]}
            ]},
            {body, [{class, ~"bg-gray-50 min-h-screen"}], [
                {nav, [{class, ~"bg-indigo-700 text-white px-6 py-4"}], [
                    {'div', [{class, ~"max-w-5xl mx-auto flex items-center justify-between"}], [
                        {a, [{href, ~"/"}, az_navigate], ~"Erlang Secure Coding"},
                        {span, [{class, ~"text-indigo-200 text-sm"}],
                            ~"Interactive Security Curriculum"}
                    ]}
                ]},
                {main, [{class, ~"max-w-5xl mx-auto px-6 py-8"}], ?inner_content},
                {footer, [{class, ~"text-center text-gray-400 text-sm py-8"}],
                    ~"Built with Nova + Arizona"},
                {script, [{type, ~"module"}],
                    ~"""
                    import { connect } from '/arizona/arizona.min.js';
                    import { connect as connectReloader } from '/arizona/arizona-reloader.min.js';
                    connect('/ws');
                    connectReloader('/arizona/reload');
                    """}
            ]}
        ]}
    ]).
