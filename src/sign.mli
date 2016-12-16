(** This module extends the Base [Sign] module with bin_io *)

open! Import

type t = Base.Sign.t = Neg | Zero | Pos [@@deriving typerep]

include module type of Base.Sign with type t := t

(** This provides [to_string]/[of_string], sexp/bin_io conversion, Map, Hashtbl, etc. *)
include Identifiable.S
  with type t := t
   and type comparator_witness := comparator_witness

module Stable : sig
  module V1 : sig
    type nonrec t = t = Neg | Zero | Pos [@@deriving bin_io, compare, hash, sexp]
  end
end