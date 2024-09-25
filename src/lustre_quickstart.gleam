import gleam/dynamic
import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Model {
  Model(count: Int, cats: List(#(Int, String)), next_id: Int)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(0, [], 0), effect.none())
}

pub type Msg {
  UserIncrementedCount
  UserDecrementedCount
  ApiReturnedCat(Result(String, lustre_http.HttpError))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserIncrementedCount -> #(Model(..model, count: model.count + 1), get_cat())
    UserDecrementedCount -> #(
      Model(model.count - 1, list.drop(model.cats, 1), model.next_id),
      effect.none(),
    )
    ApiReturnedCat(Ok(cat)) -> #(
      Model(model.count, [#(model.next_id, cat), ..model.cats], model.next_id + 1),
      effect.none(),
    )
    ApiReturnedCat(Error(_)) -> #(model, effect.none())
  }
}

fn get_cat() -> effect.Effect(Msg) {
  let decoder = dynamic.field("_id", dynamic.string)
  let expect = lustre_http.expect_json(decoder, ApiReturnedCat)
  lustre_http.get("https://cataas.com/cat?json=true", expect)
}

pub fn view(model: Model) -> element.Element(Msg) {
  let count = int.to_string(model.count)

  html.div([], [
    html.button([event.on_click(UserIncrementedCount)], [element.text("+")]),
    element.text(count),
    html.button([event.on_click(UserDecrementedCount)], [element.text("-")]),
    element.keyed(
      html.div([], _),
      list.map(model.cats, fn(item) {
        let #(id, cat) = item
        #(
          int.to_string(id),
          html.img([attribute.src("https://cataas.com/cat/" <> cat)]),
        )
      }),
    ),
  ])
}
