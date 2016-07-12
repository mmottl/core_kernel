include Core_list0

module For_quickcheck = struct

  module Generator = Quickcheck.Generator
  module Observer  = Quickcheck.Observer
  module Shrinker  = Quickcheck.Shrinker

  open Generator.Monad_infix

  let gen' ?length elem_gen =
    let min_len, max_len =
      match length with
      | None         -> None, None
      | Some variant ->
        match variant with
        | `Exactly           n      -> Some n, Some n
        | `At_least          n      -> Some n, None
        | `At_most           n      -> None,   Some n
        | `Between_inclusive (x, y) -> Some x, Some y
    in
    Generator.list elem_gen ?min_len ?max_len

  let gen elem_gen =
    gen' elem_gen

  let rec gen_permutations list =
    match list with
    | []        -> Generator.singleton []
    | x :: list ->
      gen_permutations list
      >>= fun list ->
      Quickcheck.For_int.gen_between
        ~lower_bound:(Incl 0)
        ~upper_bound:(Incl (length list))
      >>| fun index ->
      let prefix, suffix = split_n list index in
      prefix @ [ x ] @ suffix

  let obs elem_obs =
    Observer.recursive (fun t_obs ->
      Observer.unmap
        (Observer.variant2
           (Observer.singleton ())
           (Observer.tuple2 elem_obs t_obs))
        ~f:(function
          | []        -> `A ()
          | x :: list -> `B (x, list)))

  let shrinker t_elt =
    Shrinker.recursive (fun t_list ->
      Shrinker.create (function
        | []    -> Sequence.empty
        | h::tl ->
          let open Sequence.Monad_infix in
          let dropped     = Sequence.singleton tl in
          let shrunk_head = Shrinker.shrink t_elt   h >>| fun shr_h  -> shr_h::tl in
          let shrunk_tail = Shrinker.shrink t_list tl >>| fun shr_tl -> h::shr_tl in
          Sequence.interleave
            (Sequence.of_list [dropped; shrunk_head; shrunk_tail])))

  let%test_module "shrinker" =
    (module struct

      open Sexplib.Std
      module Sexp = Sexplib.Sexp

      let t0 =
        Shrinker.create (fun v ->
          if Pervasives.(=) 0 v
          then Sequence.empty
          else Sequence.singleton 0)

      let test_list = [1;2;3]
      let expect =
        [[2;3]; [0;2;3]; [1;3]; [1;0;3]; [1;2]; [1;2;0]]
        |> List.sort ~cmp:[%compare: int list ]

      let%test_unit "shrinker produces expected outputs" =
        let shrunk =
          Shrinker.shrink (shrinker t0) test_list
          |> Sequence.to_list
          |> List.sort ~cmp:[%compare: int list ]
        in
        [%test_result: int list list] ~expect shrunk

      let rec recursive_list = 1::5::recursive_list

      let%test_unit "shrinker on infinite lists produces values" =
        let shrunk = Shrinker.shrink (shrinker t0) recursive_list in
        let result_length = Sequence.take shrunk 5 |> Sequence.to_list |> List.length in
        [%test_result: int] ~expect:5 result_length
    end)

end

let gen              = For_quickcheck.gen
let gen'             = For_quickcheck.gen'
let gen_permutations = For_quickcheck.gen_permutations
let obs              = For_quickcheck.obs
let shrinker         = For_quickcheck.shrinker
