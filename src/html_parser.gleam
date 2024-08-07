import gleam/io
import gleam/string

pub fn main() {
  io.debug("<div>inside</div>")
}

pub type Element {
  EmptyElement
  StartElement(name: String, attributes: List(Attribute))
  EndElement(name: String)
}

pub type Attribute {
  Attribute(key: String, value: String)
}

pub fn get_first_element(in: String) -> #(Element, String) {
  do_get_first_element(in, "", True)
}

fn do_get_first_element(
  in: String,
  out: String,
  start: Bool,
) -> #(Element, String) {
  case in {
    "</" <> remain -> do_get_first_element(remain, out, False)
    "<" <> remain -> do_get_first_element(remain, out, True)
    ">" <> remain ->
      case start {
        True -> #(StartElement(out, []), remain)
        False -> #(EndElement(out), remain)
      }
    " " <> remain -> do_get_first_element(remain, out, start)
    "" -> #(EmptyElement, in)
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      do_get_first_element(remain, out <> head, start)
    }
  }
}

pub fn get_attrs(in: String) -> List(Attribute) {
  do_get_attrs(in, "", "", False)
}

fn do_get_attrs(
  in: String,
  key: String,
  val: String,
  finding_value: Bool,
) -> List(Attribute) {
  case in {
    "" | ">" -> [Attribute(key, val)]
    " " <> remain if !finding_value ->
      do_get_attrs(remain, key, val, finding_value)
    " " <> remain -> [
      Attribute(key, val),
      ..do_get_attrs(remain, "", "", False)
    ]
    "=" <> remain -> do_get_attrs(remain, key, "", True)
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      case finding_value {
        True -> do_get_attrs(remain, key, val <> head, finding_value)
        False -> do_get_attrs(remain, key <> head, "", finding_value)
      }
    }
  }
}
