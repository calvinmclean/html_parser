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
  in
  |> trim_space_to_elem_begin
  |> do_get_first_element("", True)
}

fn trim_space_to_elem_begin(in: String) -> String {
  case in {
    " " <> remain -> trim_space_to_elem_begin(remain)
    "<" <> remain -> "<" <> remain
    _ -> in
  }
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
    " " <> remain if start -> #(StartElement(out, get_attrs(remain)), "")
    "" -> #(EmptyElement, in)
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      do_get_first_element(remain, out <> head, start)
    }
  }
}

pub fn get_attrs(in: String) -> List(Attribute) {
  in
  |> trim_space_to_elem_begin
  |> do_get_attrs("", "", False)
}

fn do_get_attrs(
  in: String,
  key: String,
  val: String,
  finding_value: Bool,
) -> List(Attribute) {
  case in {
    "" | ">" ->
      case key, val {
        "", "" -> []
        _, _ -> [Attribute(key, val)]
      }
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
