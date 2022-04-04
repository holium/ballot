import React, { FC, useCallback, useEffect, useState } from "react";
import {
  CenteredPane,
  Grid,
  Flex,
  Box,
  Card,
  Text,
  KPI,
  TlonIcon,
  Ship,
  BreadcrumbNav,
  Fill,
  Grid2,
} from "@holium/design-system";
import MDEditor from "@uiw/react-md-editor";
import rehypeSanitize from "rehype-sanitize";
import { useNavigate, useParams } from "react-router";
import { toJS } from "mobx";
import { Observer, observer } from "mobx-react-lite";
import { VoteCard } from "../../../components/VoteCard";
import {
  createPath,
  getKeyFromUrl,
  getNameFromUrl,
} from "../../../logic/utils/path";
import { descriptiveTimeString } from "../../../logic/utils/time";
import { DetailHeader, DetailBody } from "./Detail.styles";
import { Status } from "../../../components/Status";
import { useMst } from "../../../logic/stores/root";
import { ProposalModelType } from "../../../logic/stores/proposals";
import { ProposalResult } from "./ProposalResults";

export const ProposalDetail: FC = observer((props: any) => {
  const navigate = useNavigate();
  const urlParams = useParams();
  const { store, app } = useMst();
  // const currentBooth = urlParams.boothName!;
  // const currentBoothName = getNameFromUrl(urlParams);
  const currentBoothKey = getKeyFromUrl(urlParams);
  store.setBooth(currentBoothKey);

  const [height, setHeight] = useState(null);
  const div = useCallback(
    (node) => {
      if (node !== null) {
        setHeight(node.getBoundingClientRect().height);
      }
    },
    [urlParams.proposalId!]
  );

  const onVote = (vote: { proposalId: string; chosenVote: any }) => {
    const proposal = store.booth!.proposalStore.proposals.get(
      urlParams.proposalId!
    )!;
    proposal.castVote(vote.chosenVote);
  };

  const onBack = () => {
    let newPath = createPath(getKeyFromUrl(urlParams), "proposals");
    navigate(newPath);
    app.setCurrentUrl(newPath, "proposals");
  };

  let content;
  // If the proposal store has loaded, render the page

  const booth = store.booth!;
  if (store.isLoaded && booth.proposalStore.isLoaded) {
    let proposal: ProposalModelType = booth.proposalStore.proposals.get(
      urlParams.proposalId!
    )!;
    const chosenVote = proposal.results!.getMyVote;

    const isActive = proposal.status === "Active";
    const startTime = new Date(proposal.start * 1000);
    const endTime = new Date(proposal.end * 1000);
    content = (
      <Grid2.Row reverse={["xs"]} justify="center">
        <Grid2.Column mb="16px" md={6} lg={9} xl={9}>
          <Card
            padding={0}
            style={{
              borderColor: "transparent",
              borderWidth: 0,
            }}
            elevation="lifted"
          >
            <DetailHeader>
              <Flex flex={1} flexDirection="row" justifyContent="space-between">
                <Text variant="h4" fontWeight={600}>
                  {proposal.title}
                </Text>
                <Observer>{() => <Status status={proposal.status} />}</Observer>
              </Flex>
              <Flex
                mt={2}
                flexDirection="row"
                justifyContent="space-between"
                alignItems="center"
              >
                <Ship patp={proposal.owner} color="#000000" />
                <KPI
                  icon={<TlonIcon icon="Clock" />}
                  value={descriptiveTimeString(proposal.start, proposal.end)}
                />
              </Flex>
              <Flex
                mt={3}
                flex={1}
                flexDirection="row"
                justifyContent="space-between"
              >
                <KPI
                  icon={<TlonIcon icon="Clock" />}
                  value={
                    startTime.toLocaleDateString() +
                    " " +
                    startTime.toLocaleTimeString()
                  }
                />
                <KPI
                  icon={<TlonIcon icon="Clock" />}
                  value={
                    endTime.toLocaleDateString() +
                    " " +
                    endTime.toLocaleTimeString()
                  }
                />
              </Flex>
            </DetailHeader>
            {proposal.status === "Ended" && (
              <ProposalResult proposal={proposal} />
            )}
            <DetailBody>
              <MDEditor.Markdown
                style={{
                  padding: 16,
                  borderBottomLeftRadius: 6,
                  borderBottomRightRadius: 6,
                  background: "transparent",
                  fontFamily: "Inter, sans-serif",
                }}
                source={proposal.content}
                rehypePlugins={[[rehypeSanitize]]}
              />
            </DetailBody>
          </Card>
        </Grid2.Column>
        <Grid2.Column mb="16px" md={2} lg={3}>
          <VoteCard
            disabled={!isActive}
            choices={proposal.choices}
            title={proposal.title}
            loading={proposal.isVoteLoading}
            currentUser={app.ship}
            strategy={proposal.strategy}
            onVote={onVote}
            timeLeft={descriptiveTimeString(proposal.start, proposal.end)}
            chosenOption={chosenVote && chosenVote.choice}
            voteResults={proposal.results!.resultSummary}
            voteSubmitted={proposal.results!.didVote}
          />

          {/* <Grid2.Row>
            <Card
              padding={12}
              style={{ top: 300, borderColor: "transparent", borderWidth: 0 }}
              elevation="lifted"
              // height="fit-content"
            >
              <Text fontWeight="600" variant="h6" mb="12px">
                Configuration
              </Text>
              <Grid gridTemplateRows="auto" gridRowGap="12px">
                <KPI mt={1} inline label="Strategy" value={proposal.strategy} />
                <KPI inline label="Support" value={`${proposal.support}%`} />
                <KPI
                  inline
                  label="Start date"
                  value={new Date(proposal.start).toISOString().split("T")[0]}
                />
                <KPI
                  inline
                  label="End date"
                  value={new Date(proposal.end).toISOString().split("T")[0]}
                />
                <KPI
                  inline
                  label="Created at"
                  value={
                    new Date(parseInt(proposal.created!))
                      .toISOString()
                      .split("T")[0]
                  }
                />
                <KPI inline label="Host" value={proposal.owner} />
              </Grid>
            </Card>
          </Grid2.Row> */}
        </Grid2.Column>
      </Grid2.Row>
    );
  }

  return (
    <Grid2.Box offset={40} fluid scroll ref={div}>
      <Grid2.Box>
        <Grid2.Column mb="16px" lg={12} xl={12}>
          <Grid2.Row>
            <Grid2.Column>
              <BreadcrumbNav
                onBack={onBack}
                crumbs={[
                  { label: "Proposals", onClick: onBack },
                  { label: "Details" },
                ]}
              />
            </Grid2.Column>
          </Grid2.Row>
          {content}
        </Grid2.Column>
      </Grid2.Box>
    </Grid2.Box>
  );
});
export default ProposalDetail;
