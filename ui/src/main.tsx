import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter } from "react-router-dom";
import { store, StoreContext } from "./logic/store";
import AppRoutes from "./routes";
import "./index.scss";

ReactDOM.render(
  <StoreContext.Provider value={store}>
    <BrowserRouter>{AppRoutes()}</BrowserRouter>
  </StoreContext.Provider>,
  document.getElementById("app")
);
