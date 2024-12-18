(** [Reversed_list] is constructed the same way as a list, but it needs to be reversed
    before it can be used. This is helpful when building up a list in reverse order to
    force reversal before use. *)
type 'a t =
  | []
  | ( :: ) of 'a * 'a t
[@@deriving sexp_of]

val rev : 'a t -> 'a list
val rev_append : 'a t -> 'a list -> 'a list
val rev_filter_map : 'a t -> f:('a -> 'b option) -> 'b list
val is_empty : 'a t -> bool
