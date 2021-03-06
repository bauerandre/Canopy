
open Lwt.Infix
open Canopy_utils
open Canopy_config

let atom config last_commit_date content_cache =
  let cache = ref None in
  let update_atom () =
    let l = KeyMap.fold (fun _ x acc -> x :: acc) !content_cache []
            |> List.sort Canopy_content.compare
            |> resize 10 in
    let entries = List.map Canopy_content.to_atom l in
    let ns_prefix _ = Some "" in
    last_commit_date () >|= fun updated ->
    Syndic.Atom.feed
      ~id:(Uri.of_string config.blog_name)
      ~title:(Syndic.Atom.Text config.blog_name : Syndic.Atom.text_construct)
      ~updated
      ~links:[Syndic.Atom.link ~rel:Syndic.Atom.Self (Uri.of_string "/atom")]
      entries
    |> fun feed -> Syndic.Atom.to_xml feed
    |> fun x -> Syndic.XML.to_string ~ns_prefix x
    |> fun body -> cache := Some body; body
  in
  (fun () -> ignore (update_atom ()); Lwt.return ()),
  (fun () -> match !cache with
     | Some body -> Lwt.return body
     | None -> update_atom ())
