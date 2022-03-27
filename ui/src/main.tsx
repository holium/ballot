import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter } from "react-router-dom";
// import { store, StoreContext } from "./logic/store";
import { Provider, rootStore } from "./logic/stores/root";
import AppRoutes from "./routes";
import "./index.scss";

ReactDOM.render(
  <Provider value={rootStore}>
    <BrowserRouter>{AppRoutes()}</BrowserRouter>
  </Provider>,
  document.getElementById("app")
);
