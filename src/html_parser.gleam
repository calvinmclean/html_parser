import gleam/list
import gleam/string

/// Element is a part of an HTML document
pub type Element {
  EmptyElement

  /// StartElement is an opening tag like <div> and can have Attributes and child Elements
  StartElement(
    name: String,
    attributes: List(Attribute),
    children: List(Element),
  )

  /// EndElement just has a name and signals the end of a block
  EndElement(name: String)

  /// Content is non-HTML parts of the document in-between StartElement and
  /// EndElement (the "hello" in `<div>hello</div>`)
  Content(String)
}

/// Attribute is an HTML attribute key-value pair
pub type Attribute {
  Attribute(key: String, value: String)
}

/// get the first Element and remaining String
pub fn get_first_element(in: String) -> #(Element, String) {
  in
  |> trim_space_to_elem_begin
  |> do_get_first_element("", None)
}

fn trim_space_to_elem_begin(in: String) -> String {
  case in {
    " " <> remain | "\n" <> remain | "\t" <> remain ->
      trim_space_to_elem_begin(remain)
    "<" <> remain -> "<" <> remain
    _ -> in
  }
}

/// CurrentElementType is used to track the current parsing state in do_get_first_element
type CurrentElementType {
  Start
  End
  None
}

fn do_get_first_element(
  in: String,
  out: String,
  currently_parsing: CurrentElementType,
) -> #(Element, String) {
  case in {
    "</" <> remain ->
      case out {
        "" -> do_get_first_element(remain, out, End)
        _ -> #(Content(out), "</" <> remain)
      }
    "<" <> remain ->
      case out {
        "" -> do_get_first_element(remain, out, Start)
        _ -> #(Content(out), "<" <> remain)
      }
    ">" <> remain ->
      case currently_parsing {
        Start -> #(StartElement(out, [], []), remain)
        End -> #(EndElement(out), remain)
        None -> #(Content(out), remain)
      }
    " " <> remain | "\n" <> remain | "\t" <> remain
      if currently_parsing == Start
    -> {
      let #(attrs, remain_after_attr) = get_attrs(remain)
      #(StartElement(out, attrs, []), remain_after_attr)
    }
    "" -> #(EmptyElement, "")
    _ -> {
      let assert Ok(#(head, remain)) = string.pop_grapheme(in)
      do_get_first_element(remain, out <> head, currently_parsing)
    }
  }
}

/// get the attributes for a StartElement and remaining String
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

// create a list of Elements
pub fn as_list(in: String) -> List(Element) {
  case in {
    "" -> []
    _ -> {
      let #(first, remain) = get_first_element(in)
      [first, ..as_list(remain)]
    }
  }
}

// create a tree of Elements where each StartElement can have children
pub fn as_tree(in: String) -> Element {
  let #(first, remain) = get_first_element(in)
  let #(result, _) = do_as_tree(remain, first)
  result
}

fn do_as_tree(in: String, current: Element) -> #(Element, String) {
  case current {
    Content(_) -> #(current, in)
    StartElement(cur_name, cur_attrs, cur_children) -> {
      case in {
        // If there's no more input and we're processing a StartElement,
        // we should treat it as self-closing
        "" -> #(
          StartElement(cur_name, cur_attrs, cur_children |> list.reverse),
          "",
        )
        _ -> {
          let #(next, remain) = get_first_element(in)
          case next {
            EndElement(name) if name == cur_name -> #(
              StartElement(cur_name, cur_attrs, cur_children |> list.reverse),
              remain,
            )
            EndElement(_) -> do_as_tree(remain, current)
            EmptyElement ->
              case remain {
                // Don't process empty elements with no remaining input
                "" -> #(
                  StartElement(
                    cur_name,
                    cur_attrs,
                    cur_children |> list.reverse,
                  ),
                  "",
                )
                _ ->
                  do_as_tree(
                    remain,
                    StartElement(cur_name, cur_attrs, [next, ..cur_children]),
                  )
              }
            _ -> {
              let #(child_tree, remain_after_child) = do_as_tree(remain, next)
              do_as_tree(
                remain_after_child,
                StartElement(cur_name, cur_attrs, [child_tree, ..cur_children]),
              )
            }
          }
        }
      }
    }
    _ -> #(current, in)
  }
}
