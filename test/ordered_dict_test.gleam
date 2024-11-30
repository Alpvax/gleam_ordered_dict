import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import ordered_dict as od

pub fn main() {
  gleeunit.main()
}

pub fn from_list_test() {
  [#(4, 0), #(1, 0)]
  |> od.from_list
  |> od.size
  |> should.equal(2)

  [#(1, 0), #(1, 1)]
  |> od.from_list
  |> should.equal(od.from_list([#(1, 1)]))

  [#(1, 0), #(2, 1), #(1, 2)]
  |> od.from_list
  |> should.equal(od.from_list([#(2, 1), #(1, 2)]))
}

pub fn has_key_test() {
  []
  |> od.from_list
  |> od.has_key(1)
  |> should.be_false

  [#(1, 0)]
  |> od.from_list
  |> od.has_key(1)
  |> should.be_true

  [#(4, 0), #(1, 0)]
  |> od.from_list
  |> od.has_key(1)
  |> should.be_true

  [#(4, 0), #(1, 0)]
  |> od.from_list
  |> od.has_key(0)
  |> should.be_false
}

pub fn new_test() {
  od.new()
  |> od.size
  |> should.equal(0)

  od.new()
  |> od.to_list
  |> should.equal([])
}

type Key {
  A
  B
  C
}

pub fn get_test() {
  let proplist = [#(4, 0), #(1, 1)]
  let m = od.from_list(proplist)

  m
  |> od.get(4)
  |> should.equal(Ok(0))

  m
  |> od.get(1)
  |> should.equal(Ok(1))

  m
  |> od.get(2)
  |> should.equal(Error(Nil))

  let proplist = [#(A, 0), #(B, 1)]
  let m = od.from_list(proplist)

  m
  |> od.get(A)
  |> should.equal(Ok(0))

  m
  |> od.get(B)
  |> should.equal(Ok(1))

  m
  |> od.get(C)
  |> should.equal(Error(Nil))

  let proplist = [#(<<1, 2, 3>>, 0), #(<<3, 2, 1>>, 1)]
  let m = od.from_list(proplist)

  m
  |> od.get(<<1, 2, 3>>)
  |> should.equal(Ok(0))

  m
  |> od.get(<<3, 2, 1>>)
  |> should.equal(Ok(1))

  m
  |> od.get(<<1, 3, 2>>)
  |> should.equal(Error(Nil))
}

pub fn insert_test() {
  od.new()
  |> od.insert_end("a", 0)
  |> od.insert(0, "b", 1)
  |> od.prepend("c", 2)
  |> should.equal(od.from_list([#("c", 2), #("b", 1), #("a", 0)]))
}

pub fn map_values_test() {
  [#(1, 0), #(2, 1), #(3, 2)]
  |> od.from_list
  |> od.map_values(fn(k, v, _) { k + v })
  |> should.equal(od.from_list([#(1, 1), #(2, 3), #(3, 5)]))
}

pub fn keys_test() {
  [#("a", 0), #("b", 1), #("c", 2)]
  |> od.from_list
  |> od.keys
  |> list.sort(string.compare)
  |> should.equal(["a", "b", "c"])
}

pub fn values_test() {
  [#("a", 0), #("b", 1), #("c", 2)]
  |> od.from_list
  |> od.values
  |> should.equal([0, 1, 2])
}

pub fn take_test() {
  [#("a", 0), #("b", 1), #("c", 2)]
  |> od.from_list
  |> od.take(["a", "b", "d"])
  |> should.equal(od.from_list([#("a", 0), #("b", 1)]))
}

pub fn drop_test() {
  [#("a", 0), #("b", 1), #("c", 2)]
  |> od.from_list
  |> od.drop(["a", "b", "d"])
  |> should.equal(od.from_list([#("c", 2)]))
}

pub fn delete_test() {
  [#("a", 0), #("b", 1), #("c", 2)]
  |> od.from_list
  |> od.delete("a")
  |> od.delete("d")
  |> should.equal(od.from_list([#("b", 1), #("c", 2)]))
}

pub fn upsert_test() {
  let od = od.from_list([#("a", 0), #("b", 1), #("c", 2)])

  let inc_or_zero = fn(x) {
    case x {
      od.Update(i, f) -> f(i + 1)
      od.Insert(f) -> f(od.End, 0)
    }
  }

  od
  |> od.upsert("a", inc_or_zero)
  |> should.equal(od.from_list([#("a", 1), #("b", 1), #("c", 2)]))

  od
  |> od.upsert("b", inc_or_zero)
  |> should.equal(od.from_list([#("a", 0), #("b", 2), #("c", 2)]))

  od
  |> od.upsert("z", inc_or_zero)
  |> should.equal(od.from_list([#("a", 0), #("b", 1), #("c", 2), #("z", 0)]))
}

pub fn fold_test() {
  let od = od.from_list([#("a", 0), #("b", 1), #("c", 2), #("d", 3)])

  let add = fn(acc, _, v, _) { v + acc }

  od
  |> od.fold(0, add)
  |> should.equal(6)

  let prepend = fn(acc, k, _, _) { list.prepend(acc, k) }

  od
  |> od.fold([], prepend)
  |> list.sort(string.compare)
  |> should.equal(["a", "b", "c", "d"])

  od.from_list([])
  |> od.fold(0, add)
  |> should.equal(0)
}

pub fn each_test() {
  let od = od.from_list([#("a", 1), #("b", 2), #("c", 3), #("d", 4)])

  od.each(od, fn(k, v, _) {
    let assert True = case k, v {
      "a", 1 | "b", 2 | "c", 3 | "d", 4 -> True
      _, _ -> False
    }
  })
  |> should.equal(Nil)
}

fn range(start, end, a) {
  case end - start {
    n if n < 1 -> a
    _ -> range(start, end - 1, [end - 1, ..a])
  }
}

fn list_to_map(list) {
  list
  |> list.map(fn(n) { #(n, n) })
  |> od.from_list
}

fn grow_and_shrink_map(initial_size, final_size) {
  range(0, initial_size, [])
  |> list_to_map
  |> list.fold(
    range(final_size, initial_size, []),
    _,
    fn(map, item) { od.delete(map, item) },
  )
}

// ensure operations on a map don't mutate it
pub fn persistence_test() {
  let a = list_to_map([0])
  od.insert(a, 99, 0, 5)
  od.insert(a, 0, 1, 6)
  od.delete(a, 0)
  od.get(a, 0)
  |> should.equal(Ok(0))
}

pub fn large_n_test() {
  let n = 10_000
  let l = range(0, n, [])

  let m = list_to_map(l)
  list.map(l, fn(i) { should.equal(od.get(m, i), Ok(i)) })

  let m = grow_and_shrink_map(n, 0)
  list.map(l, fn(i) { should.equal(od.get(m, i), Error(Nil)) })
}

pub fn size_test() {
  let n = 1000
  let m = list_to_map(range(0, n, []))
  od.size(m)
  |> should.equal(n)

  let m = grow_and_shrink_map(n, n / 2)
  od.size(m)
  |> should.equal(n / 2)

  let m =
    grow_and_shrink_map(n, 0)
    |> od.delete(0)
  od.size(m)
  |> should.equal(0)

  let m = list_to_map(range(0, 18, []))

  od.prepend(m, 1, 99)
  |> od.size()
  |> should.equal(18)
  od.prepend(m, 2, 99)
  |> od.size()
  |> should.equal(18)
}

pub fn is_empty_test() {
  od.new()
  |> od.is_empty()
  |> should.be_true()

  od.new()
  |> od.prepend(1, 10)
  |> od.is_empty()
  |> should.be_false()

  od.new()
  |> od.prepend(1, 10)
  |> od.delete(1)
  |> od.is_empty()
  |> should.be_true()
}

pub fn zero_must_be_contained_test() {
  let map =
    od.new()
    |> od.prepend(0, Nil)

  map
  |> od.get(0)
  |> should.equal(Ok(Nil))

  map
  |> od.has_key(0)
  |> should.equal(True)
}

pub fn empty_map_equality_test() {
  let map1 = od.new()
  let map2 = od.from_list([#(1, 2)])

  should.be_false(map1 == map2)
  should.be_false(map2 == map1)
}

pub fn extra_keys_equality_test() {
  let map1 = od.from_list([#(1, 2), #(3, 4)])
  let map2 = od.from_list([#(1, 2), #(3, 4), #(4, 5)])

  should.be_false(map1 == map2)
  should.be_false(map2 == map1)
}
