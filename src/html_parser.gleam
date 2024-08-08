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
  start_element: Bool,
) -> #(Element, String) {
  case in {
    "</" <> remain -> do_get_first_element(remain, out, False)
    "<" <> remain -> do_get_first_element(remain, out, True)
    ">" <> remain ->
      case start_element {
        True -> #(StartElement(out, []), remain)
        False -> #(EndElement(out), remain)
      }
    " " <> remain | "\n" <> remain | "\t" <> remain if start_element -> {
      let #(attrs, remain_after_attr) = get_attrs(remain)
      #(StartElement(out, attrs), remain_after_attr)
    }
    "" -> #(EmptyElement, "")
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      do_get_first_element(remain, out <> head, start_element)
    }
  }
}

pub fn get_attrs(in: String) -> #(List(Attribute), String) {
  in
  |> trim_space_to_elem_begin
  |> do_get_attrs("", "", False)
}

fn do_get_attrs(
  in: String,
  key: String,
  val: String,
  finding_value: Bool,
) -> #(List(Attribute), String) {
  case in {
    "" | ">" ->
      case key, val {
        "", "" -> #([], "")
        _, "" -> #([], key)
        _, _ -> #([Attribute(key, remove_quotes(val))], "")
      }
    ">" <> remain ->
      case key, val {
        "", "" -> #([], remain)
        _, _ -> #([Attribute(key, remove_quotes(val))], remain)
      }
    " " <> remain | "\n" <> remain | "\t" <> remain if !finding_value ->
      do_get_attrs(remain, key, val, finding_value)
    " " <> remain | "\n" <> remain | "\t" <> remain -> {
      let #(attrs, remain_after_attr) = do_get_attrs(remain, "", "", False)
      #([Attribute(key, remove_quotes(val)), ..attrs], remain_after_attr)
    }
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

fn remove_quotes(in: String) -> String {
  let remove_first_quote = fn(str) {
    case str {
      "\"" <> remain -> remain
      _ -> str
    }
  }

  in
  |> remove_first_quote
  |> string.reverse
  |> remove_first_quote
  |> string.reverse
}
