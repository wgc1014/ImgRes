-module(event).
-compile(export_all).
-record(state, {server,
		client,
		name="",
		path="",
		options=""}).

start(Client,EventName, PathName,Options) ->
	spawn(?MODULE,init,[self(),Client,EventName,PathName,Options]).

start_link(Client,EventName, PathName,Options) ->
	spawn_link(?MODULE,init,[self(),Client,EventName,PathName,Options]).

init(Server,Client,EventName,PathName,Options) ->
	loop(#state{server=Server,
			client=Client,
			name=EventName,
			path=PathName,
			options=Options}).

cancel(Pid) ->
	Ref = erlang:monitor(process,Pid),
	Pid ! {self(),Ref,cancel},
	receive
		{Ref,ok} ->
			erlang:demonitor(Ref,[flush]),
			ok;
		{'DOWN',Ref,process,Pid,_Reason} ->
			ok
	end.



loop(S = #state{server=Server}) ->
	receive
		{Server, Ref, cancel} ->
			Server ! {Ref, ok}
	after 1000 ->
		% Rename the path to save the file as /path/Resized_filename
		[Filename|_] = lists:reverse(string:tokens(S#state.path,"/")),
		Newfilename = string:concat(Filename,".jpg"),
		% Hardcoded url,ARGH!
		NewPath2 = string:concat("/home/admins/albertadm/imgRes/priv/www/",Newfilename),
		{Action,SizeX,SizeY} = S#state.options,
		gm:convert(S#state.path, NewPath2 ,[{list_to_atom(Action), list_to_integer(SizeX), list_to_integer(SizeY)}]),
		Server ! {done, S#state.name, Newfilename}
	end.


