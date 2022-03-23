import React, { useContext, createContext, useState } from "react";
import { Routes, Route, Link } from "react-router-dom";
import { App, appName } from "./app";
// /proposals
import { Proposals } from "./pages/Proposals";
import { ProposalList } from "./pages/Proposals/List";
import { ProposalDetail } from "./pages/Proposals/Detail";
import { ProposalEditor } from "./pages/Proposals/Editor";
// /delegate
import { Delegation } from "./pages/Delegation";
import { DelegationList } from "./pages/Delegation/List";
// /settings
import { Settings } from "./pages/Settings";
import { Navigate } from "react-router-dom";

export default function AppRoutes() {
  return (
    <Routes>
      <Route path={`/apps/${appName}/`} element={<App />}>
        <Route
          path={`/apps/${appName}/booth/:type/:boothName/proposals`}
          element={<Proposals />}
        >
          <Route index element={<ProposalList />} />
          <Route
            path={`/apps/${appName}/booth/:type/:boothName/proposals/:proposalId`}
            element={<ProposalDetail />}
          />
          <Route
            path={`/apps/${appName}/booth/:type/:boothName/proposals/create-new`}
            element={<ProposalEditor />}
          />
          <Route
            path={`/apps/${appName}/booth/:type/:boothName/proposals/editor/:proposalId`}
            element={<ProposalEditor />}
          />
        </Route>
        <Route
          path={`/apps/${appName}/booth/:type/:boothName/delegation`}
          element={<Delegation />}
        >
          <Route index element={<DelegationList />} />
        </Route>
      </Route>
      <Route path="*" element={<NoMatch />} />
    </Routes>
  );
}

function NoMatch() {
  return (
    <div style={{ padding: "12px 24px" }}>
      <h2>Nothing to see here!</h2>
      <p>
        <Link to={`/apps/${appName}/booth/`}>Go to the home page</Link>
      </p>
    </div>
  );
}
