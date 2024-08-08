import gleam/list
import gleeunit
import gleeunit/should
import html_parser

pub fn main() {
  gleeunit.main()
}

pub fn get_first_element_test() {
  let tests = [
    #("empty string", "", #(html_parser.EmptyElement, "")),
    #("div", "<div>", #(html_parser.StartElement("div", []), "")),
    #("end div", "</div>", #(html_parser.EndElement("div"), "")),
    #("end div with leading spaces", "     </div>", #(
      html_parser.EndElement("div"),
      "",
    )),
    #("div with leading spaces", "   <div>", #(
      html_parser.StartElement("div", []),
      "",
    )),
    #("div with internal spaces", "<div \t \n  >", #(
      html_parser.StartElement("div", []),
      "",
    )),
    #("div with remaining", "<div>  <div>", #(
      html_parser.StartElement("div", []),
      "  <div>",
    )),
    #("div with attribute", "<div\n a=\"b\">", #(
      html_parser.StartElement("div", [html_parser.Attribute("a", "b")]),
      "",
    )),
    #("div with attribute and too many spaces", "<div     a=\"b\" >", #(
      html_parser.StartElement("div", [html_parser.Attribute("a", "b")]),
      "",
    )),
    #("div with multiple attribute", "<div a=\"b\" c=\"d\">", #(
      html_parser.StartElement("div", [
        html_parser.Attribute("a", "b"),
        html_parser.Attribute("c", "d"),
      ]),
      "",
    )),
  ]

  list.each(tests, fn(testcase) {
    let #(_, in, expected) = testcase
    html_parser.get_first_element(in) |> should.equal(expected)
  })
}

pub fn get_attrs_test() {
  let tests = [
    #("empty string", "", #([], "")),
    #("single simple attr", "a=\"b\"", #([html_parser.Attribute("a", "b")], "")),
    #("surrounding spaces", "     a=\"b\"", #(
      [html_parser.Attribute("a", "b")],
      "",
    )),
    #("single larger attr", "aaaaaaa=\"bbbbbb\"", #(
      [html_parser.Attribute("aaaaaaa", "bbbbbb")],
      "",
    )),
    #("multiple simple attr", "a=\"b\" \t c=\"d\" e=\"f\"", #(
      [
        html_parser.Attribute("a", "b"),
        html_parser.Attribute("c", "d"),
        html_parser.Attribute("e", "f"),
      ],
      "",
    )),
    #("multiple larger attr", "aaaaaaa=\"bbbbbb\" ccc=\"dddd\"", #(
      [
        html_parser.Attribute("aaaaaaa", "bbbbbb"),
        html_parser.Attribute("ccc", "dddd"),
      ],
      "",
    )),
    #("attributes followed by more document", "a=\"b\" c=\"d\" > \n</div>", #(
      [html_parser.Attribute("a", "b"), html_parser.Attribute("c", "d")],
      " \n</div>",
    )),
  ]

  list.each(tests, fn(testcase) {
    let #(_, in, expected) = testcase
    html_parser.get_attrs(in) |> should.equal(expected)
  })
}

pub fn as_list_test() {
  let tests = [
    #("empty string", "", []),
    #("single start element", "<div>", [html_parser.StartElement("div", [])]),
    #("start and end element", "<div> \n \t </div>", [
      html_parser.StartElement("div", []),
      html_parser.EndElement("div"),
    ]),
    #("nested elements", "<div><p></p></div>", [
      html_parser.StartElement("div", []),
      html_parser.StartElement("p", []),
      html_parser.EndElement("p"),
      html_parser.EndElement("div"),
    ]),
  ]
  list.each(tests, fn(testcase) {
    let #(_name, in, expected) = testcase
    html_parser.as_list(in) |> should.equal(expected)
  })
}
