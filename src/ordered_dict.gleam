import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/result

// TODO: Duplication strategy
// pub type DuplicateStrategy {
//   NewIndex
//   OldIndex
//   KeepBoth
// }

pub opaque type OrderedDict(k, v) {
  OrderedDict(map: dict.Dict(k, v), order: List(k))
}

pub fn new() -> OrderedDict(k, v) {
  OrderedDict(dict.new(), [])
}

/// Converts a list of 2-element tuples `#(key, value)` to an ordered dict.
///
/// If two tuples have the same key the last one in the list will be the one
/// that is present in the dict, and .
///
pub fn from_list(entries: List(#(k, v))) -> OrderedDict(k, v) {
  let #(d, rev) = {
    use #(map, rev_order), #(key, val) <- list.fold(entries, #(dict.new(), []))
    #(dict.insert(map, key, val), [key, ..rev_order])
  }
  OrderedDict(d, list.reverse(rev))
}

/// Determines whether or not a value present in the dict for a given key.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert_end("a", 0) |> has_key("a")
/// // -> True
/// ```
///
/// ```gleam
/// new() |> insert_end("a", 0) |> has_key("b")
/// // -> False
/// ```
///
pub fn has_key(o_dict: OrderedDict(k, v), key: k) -> Bool {
  dict.has_key(o_dict.map, key)
}

/// Determines the number of key-value pairs in the dict.
/// This function runs in constant time and does not need to iterate the dict.
///
/// ## Examples
///
/// ```gleam
/// new() |> size
/// // -> 0
/// ```
///
/// ```gleam
/// new() |> insert_end("key", "value") |> size
/// // -> 1
/// ```
///
pub fn size(o_dict: OrderedDict(k, v)) -> Int {
  list.length(o_dict.order)
}

/// Determines whether or not the dict is empty.
///
/// ## Examples
///
/// ```gleam
/// new() |> is_empty
/// // -> True
/// ```
///
/// ```gleam
/// new() |> insert_end("b", 1) |> is_empty
/// // -> False
/// ```
///
pub fn is_empty(o_dict: OrderedDict(k, v)) -> Bool {
  dict.is_empty(o_dict.map)
}

/// Inserts a value into the dict with the given key as the first item.
///
/// If the dict already has a value for the given key then the value is replaced with the new value.
/// 
/// ## Examples
/// 
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> prepend("c", 2)
/// // -> from_list([#("c", 2), #("a", 0), #("b", 1)])
/// ```
/// 
pub fn prepend(
  into o_dict: OrderedDict(k, v),
  for key: k,
  value val: v,
) -> OrderedDict(k, v) {
  OrderedDict(dict.insert(o_dict.map, key, val), [key, ..o_dict.order])
}

/// Inserts a value into the dict with the given key as the last item.
///
/// If the dict already has a value for the given key then the value is replaced with the new value.
/// 
/// ## Examples
/// 
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> insert_end("c", 2)
/// // -> from_list([#("a", 0), #("b", 1), #("c", 2)])
/// ```
/// 
pub fn insert_end(
  into o_dict: OrderedDict(k, v),
  for key: k,
  value val: v,
) -> OrderedDict(k, v) {
  OrderedDict(
    dict.insert(o_dict.map, key, val),
    list.append(o_dict.order, [key]),
  )
}

/// Inserts a value into the dict with the given key and position.
///
/// If the dict already has a value for the given key then the value is replaced with the new value.
/// 
/// ## Examples
/// 
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> insert(1, "c", 2)
/// // -> from_list([#("a", 0), #("c", 2), #("b", 1)])
/// ```
/// 
pub fn insert(
  into o_dict: OrderedDict(k, v),
  at index: Int,
  for key: k,
  value val: v,
) -> OrderedDict(k, v) {
  OrderedDict(dict.insert(o_dict.map, key, val), case
    list.split(o_dict.order, index)
  {
    #(pre, []) -> list.append(pre, [key])
    #(pre, post) -> list.append(pre, [key, ..post])
  })
}

/// Fetches a key from a dict at a given index.
///
/// The dict may not have a key for the index, so the key is wrapped in a
/// `Result`.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert("a", 0) |> get_key_at(0)
/// // -> Ok("a")
/// ```
///
/// ```gleam
/// new() |> insert("a", 0) |> get_key_at(1)
/// // -> Error(Nil)
/// ```
///
pub fn get_key_at(
  from o_dict: OrderedDict(k, v),
  at index: Int,
) -> Result(k, Nil) {
  case list.split(o_dict.order, index) {
    #(_, []) -> Error(Nil)
    #(_, [key, ..]) -> Ok(key)
  }
}

/// Fetches a value from a dict at a given index.
///
/// The dict may not have a value for the index, so the value is wrapped in a
/// `Result`.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert("a", 0) |> get_value_at(0)
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// new() |> insert("a", 0) |> get_value_at(1)
/// // -> Error(Nil)
/// ```
///
pub fn get_value_at(
  from o_dict: OrderedDict(k, v),
  at index: Int,
) -> Result(v, Nil) {
  case list.split(o_dict.order, index) {
    #(_, []) -> Error(Nil)
    #(_, [key, ..]) -> dict.get(o_dict.map, key)
  }
}

/// Fetches a `#(key, value)` entry from a dict at a given index.
///
/// The dict may not have an entry for the index, so the entry is wrapped in a
/// `Result`.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert("a", 0) |> get_at(0)
/// // -> Ok(#("a",0))
/// ```
///
/// ```gleam
/// new() |> insert("a", 0) |> get_at(1)
/// // -> Error(Nil)
/// ```
///
pub fn get_at(
  from o_dict: OrderedDict(k, v),
  at index: Int,
) -> Result(#(k, v), Nil) {
  case list.split(o_dict.order, index) {
    #(_, []) -> Error(Nil)
    #(_, [key, ..]) ->
      dict.get(o_dict.map, key) |> result.map(fn(val) { #(key, val) })
  }
}

/// Fetches a value from a dict for a given key.
///
/// The dict may not have a value for the key, so the value is wrapped in a
/// `Result`.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert("a", 0) |> get("a")
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// new() |> insert("a", 0) |> get("b")
/// // -> Error(Nil)
/// ```
///
pub fn get(from o_dict: OrderedDict(k, v), for key: k) -> Result(v, Nil) {
  dict.get(o_dict.map, key)
}

/// Fetches an index from a dict for a given key.
///
/// The dict may not have an index for the key, so the index is wrapped in a
/// `Result`.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert("a", "foo") |> get("a")
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// new() |> insert("a", "foo") |> get("b")
/// // -> Error(Nil)
/// ```
///
pub fn get_index(from o_dict: OrderedDict(k, v), for key: k) -> Result(Int, Nil) {
  case has_key(o_dict, key) {
    True -> {
      let len = list.length(o_dict.order)
      let idx = {
        use i, k <- list.fold_until(o_dict.order, 0)
        case k == key {
          True -> list.Stop(i)
          _ -> list.Continue(i + 1)
        }
      }
      case idx < len {
        True -> Ok(idx)
        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Creates a new dict from a given dict with all the same entries except for the
/// one at a given index, if it exists and it is the specified key.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete_at_with_key(0, "a")
/// // -> from_list([#("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete_at_with_key(0, "b")
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete_at_with_key(1, "a")
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete_at_with_key(2, "a")
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
pub fn delete_at_with_key(
  from o_dict: OrderedDict(k, v),
  at index: Int,
  for key: k,
) -> OrderedDict(k, v) {
  case list.split(o_dict.order, index) {
    #(pre, [key_at, ..post]) if key == key_at ->
      OrderedDict(dict.delete(o_dict.map, key_at), list.append(pre, post))
    _ -> o_dict
  }
}

/// Creates a new dict from a given dict with all the same entries except for the
/// one at a given index, if it exists.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete_at(0)
/// // -> from_list([#("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete_at(2)
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
pub fn delete_at(
  from o_dict: OrderedDict(k, v),
  at index: Int,
) -> OrderedDict(k, v) {
  case list.split(o_dict.order, index) {
    #(pre, [key_at, ..post]) ->
      OrderedDict(dict.delete(o_dict.map, key_at), list.append(pre, post))
    _ -> o_dict
  }
}

/// Creates a new dict from a given dict with all the same entries except for the
/// one with a given key, if it exists.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete("a")
/// // -> from_list([#("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> delete("c")
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
pub fn delete(
  from o_dict: OrderedDict(k, v),
  delete key: k,
) -> OrderedDict(k, v) {
  OrderedDict(
    dict.delete(o_dict.map, key),
    list.filter(o_dict.order, fn(item) { item != key }),
  )
}

/// Creates a new dict from a given dict with all the same entries except any with
/// keys found in a given list.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> drop(["a"])
/// // -> from_list([#("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> drop(["c"])
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> drop(["a", "b", "c"])
/// // -> from_list([])
/// ```
///
pub fn drop(from o_dict: OrderedDict(k, v), drop disallowed_keys: List(k)) {
  OrderedDict(
    dict.drop(o_dict.map, disallowed_keys),
    list.filter(o_dict.order, fn(item) { !list.contains(disallowed_keys, item) }),
  )
}

/// Creates a new ordered dict from a given ordered dict, only including any entries
/// for which the keys are in a given list.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)])
/// |> take(["b"])
/// // -> from_list([#("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)])
/// |> take(["a", "b", "c"])
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
pub fn take(
  from o_dict: OrderedDict(k, v),
  keeping desired_keys: List(k),
) -> OrderedDict(k, v) {
  OrderedDict(
    dict.take(o_dict.map, desired_keys),
    list.filter(o_dict.order, list.contains(desired_keys, _)),
  )
}

/// Creates a new ordered dict from a given ordered dict, minus any entries that a
/// given function returns `False` for.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)])
/// |> filter(fn(key, value, _index) { value != 0 })
/// // -> from_list([#("b", 1)])
/// ```
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)])
/// |> filter(fn(key, value, _index) { True })
/// // -> from_list([#("a", 0), #("b", 1)])
/// ```
///
pub fn filter(
  in o_dict: OrderedDict(k, v),
  keeping predicate: fn(k, v, Int) -> Bool,
) -> OrderedDict(k, v) {
  to_list_indexed(o_dict)
  |> list.filter_map(fn(e) {
    case predicate(e.1, e.2, e.0) {
      True -> Ok(#(e.1, e.2))
      _ -> Error(Nil)
    }
  })
  |> from_list()
}

/// Change the order of a specific item, shifting it from one index to another.
/// 
/// ## Examples
/// 
/// ```gleam
/// from_list([#("a", 0), #("b", 1), #("c", 2)]) |> reorder(2, 0)
/// // -> from_list([#("c", 2), #("a", 0), #("b", 1)])
/// ```
/// 
/// The item will be removed and readded simultaneously, so the indices of all
/// the items between old and new indices will shift by one.
/// 
/// ```gleam
/// from_list([#("a", 0), #("b", 1), #("c", 2), #("d", 3), #("e", 4), #("f", 5)]) |> reorder(1, 3)
/// // -> from_list([#("a", 0), #("c", 2), #("d", 3), #("b", 1), #("e", 4), #("f", 5)])
/// ```
/// 
/// ```gleam
/// from_list([#("a", 0), #("b", 1), #("c", 2), #("d", 3), #("e", 4), #("f", 5)]) |> reorder(4, 2)
/// // -> from_list([#("a", 0), #("b", 1), #("e", 4), #("c", 2), #("d", 3), #("f", 5)])
/// ```
/// 
pub fn reorder(
  in o_dict: OrderedDict(k, v),
  from old_index: Int,
  to new_index: Int,
) -> OrderedDict(k, v) {
  let old = int.min(old_index, int.max(0, list.length(o_dict.order) - 1))
  let delta = int.absolute_value(new_index - old)
  OrderedDict(
    ..o_dict,
    order: case int.compare(new_index, old) {
      order.Eq -> o_dict.order
      order.Gt -> {
        let assert #(pre, [key, ..rest]) = list.split(o_dict.order, old)
        let #(mid, post) = list.split(rest, delta)
        list.flatten([pre, mid, [key], post])
      }
      order.Lt -> {
        let assert #(pre, [key, ..rest]) = list.split(o_dict.order, new_index)
        let #(mid, post) = list.split(rest, delta)
        list.flatten([pre, [key], mid, post])
      }
    },
  )
}

/// Converts the dict to an ordered list of 2-element tuples `#(key, value)`,
/// one for each key-value pair in the dict.
///
/// ## Examples
///
/// Calling `to_list` on an empty `dict` returns an empty list.
///
/// ```gleam
/// new() |> to_list
/// // -> []
/// ```
///
/// The tuples will be ordered as specified
///
/// ```gleam
/// new() |> insert_end("b", 1) |> insert_end("a", 0) |> insert_at(0, "c", 2) |> to_list
/// // -> [#("c", 2), #("b", 1), #("a", 0)]
/// ```
///
pub fn to_list(o_dict: OrderedDict(k, v)) -> List(#(k, v)) {
  use key <- list.filter_map(o_dict.order)
  dict.get(o_dict.map, key)
  |> result.map(fn(d) { #(key, d) })
}

/// Converts the dict to an ordered list of 2-element tuples `#(key, value)`,
/// one for each key-value pair in the dict.
///
/// ## Examples
///
/// Calling `to_list` on an empty `dict` returns an empty list.
///
/// ```gleam
/// new() |> to_list
/// // -> []
/// ```
///
/// The tuples will be ordered as specified
///
/// ```gleam
/// new() |> insert_end("b", 1) |> insert_end("a", 0) |> insert_at(0, "c", 2) |> to_list
/// // -> [#("c", 2), #("b", 1), #("a", 0)]
/// ```
///
pub fn to_list_indexed(o_dict: OrderedDict(k, v)) -> List(#(Int, k, v)) {
  {
    use #(out, i), key <- list.fold(o_dict.order, #([], 0))
    case dict.get(o_dict.map, key) {
      Ok(val) -> #([#(i, key, val), ..out], i + 1)
      _ -> #(out, i)
    }
  }.0
}

/// Gets a list of all keys in a given ordered dict in order.
///
/// ## Examples
///
/// ```gleam
/// from_list([#("a", 0), #("b", 1)]) |> keys
/// // -> ["a", "b"]
/// ```
///
pub fn keys(o_dict: OrderedDict(k, v)) -> List(k) {
  list.filter(o_dict.order, dict.has_key(o_dict.map, _))
}

/// Get the internal unordered dict
pub fn backing_dict(o_dict: OrderedDict(k, v)) -> dict.Dict(k, v) {
  o_dict.map
}

/// Combines all entries into a single value by calling a given function on each
/// one in order.
///
/// # Examples
///
/// ```gleam
/// let dict = from_list([#("a", 1), #("b", 3), #("c", 9)])
/// fold(dict, 0, fn(accumulator, key, value, _) { accumulator + value })
/// // -> 13
/// ```
///
/// ```gleam
/// import gleam/string
///
/// let dict = from_list([#("a", 1), #("b", 3), #("c", 9)])
/// fold(dict, "", fn(accumulator, key, value, _) {
///   string.append(accumulator, key)
/// })
/// // -> "abc"
/// ```
///
pub fn fold(
  over o_dict: OrderedDict(k, v),
  from initial: acc,
  with fun: fn(acc, k, v, Int) -> acc,
) -> acc {
  use acc, #(idx, key, val) <- list.fold(to_list_indexed(o_dict), initial)
  fun(acc, key, val, idx)
}

/// Calls a function for each key and value in order, discarding the return
/// value.
///
/// Useful for producing a side effect for every item of a dict.
///
/// ```gleam
/// import gleam/io
///
/// let dict = from_list([#("a", "apple"), #("b", "banana"), #("c", "cherry")])
///
/// each(dict, fn(k, v, _i) {
///   io.println(key <> " => " <> value)
/// })
/// // -> Nil
/// // a => apple
/// // b => banana
/// // c => cherry
/// ```
///
pub fn each(o_dict: OrderedDict(k, v), fun: fn(k, v, Int) -> a) -> Nil {
  fold(o_dict, Nil, fn(nil, k, v, i) {
    fun(k, v, i)
    nil
  })
}

/// Updates all values in a given dict by calling a given function on each key,
/// value and index.
///
/// ## Examples
///
/// ```gleam
/// from_list([#(3, 3), #(2, 4)])
/// |> map_values(fn(key, value, _index) { key * value })
/// // -> from_list([#(3, 9), #(2, 8)])
/// ```
///
pub fn map_values(
  in o_dict: OrderedDict(k, v),
  with fun: fn(k, v, Int) -> a,
) -> OrderedDict(k, a) {
  to_list_indexed(o_dict)
  |> list.map(fn(e) { #(e.1, fun(e.1, e.2, e.0)) })
  |> from_list()
}

pub type UpsertIndex {
  Start
  End
  Index(Int)
}

pub type Upsert(k, v) {
  Update(value: v, update: fn(v) -> OrderedDict(k, v))
  Insert(insert: fn(UpsertIndex, v) -> OrderedDict(k, v))
}

/// Creates a new dict with one entry inserted at the end or updated using a given function.
///
/// If there was not an entry in the dict for the given key then the function
/// gets `Insert` as its argument, otherwise it gets `Update(value)`.
///
/// ## Example
///
/// ```gleam
/// let dict = from_list([#("a", 0)])
/// let increment = fn(x) {
///   case x {
///     Update(i, update) -> update(i + 1)
///     Insert(insert) -> insert(End, 0)
///   }
/// }
///
/// upsert(dict, "a", increment)
/// // -> from_list([#("a", 1)])
///
/// upsert(dict, "b", increment)
/// // -> from_list([#("a", 0), #("b", 0)])
/// ```
///
pub fn upsert(
  in o_dict: OrderedDict(k, v),
  update key: k,
  with fun: fn(Upsert(k, v)) -> OrderedDict(k, v),
) -> OrderedDict(k, v) {
  case get(o_dict, key) {
    Ok(val) ->
      Update(val, fn(val) {
        OrderedDict(..o_dict, map: dict.insert(o_dict.map, key, val))
      })
    _ ->
      Insert(fn(index, val) {
        case index {
          Start -> prepend(o_dict, key, val)
          Index(i) if i <= 0 -> prepend(o_dict, key, val)
          Index(i) -> insert(o_dict, i, key, val)
          End -> insert_end(o_dict, key, val)
        }
      })
  }
  |> fun
}
