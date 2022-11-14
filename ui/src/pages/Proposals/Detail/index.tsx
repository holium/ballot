import React, { FC, useCallback, useEffect, useState } from "react";
import {
  Flex,
  Card,
  Text,
  KPI,
  TlonIcon,
  Ship,
  BreadcrumbNav,
  Grid2,
  Box,
  Tab,
} from "@holium/design-system";
import MDEditor from "@uiw/react-md-editor";
import rehypeSanitize from "rehype-sanitize";
import { useNavigate, useParams } from "react-router";
import { toJS } from "mobx";
import { Observer, observer } from "mobx-react-lite";
import { ActionDataTable, VoteCard } from "../../../components/VoteCard";
import { createPath, getKeyFromUrl } from "../../../logic/utils/path";
import { descriptiveTimeString, displayDate } from "../../../logic/utils/time";
import {
  DetailHeader,
  DetailBody,
  ProposalResultSection,
} from "./Detail.styles";
import { Status } from "../../../components/Status";
import { useMst } from "../../../logic/stores/root";
import {
  ChoiceModelType,
  ProposalModelType,
} from "../../../logic/stores/proposals";
import { ProposalResult } from "./ProposalResults";
import { useMobile } from "../../../logic/utils/useMobile";
import { VoteResultList } from "./VoteResultList";

export const ProposalDetail: FC = observer((props: any) => {
  const navigate = useNavigate();
  const urlParams = useParams();
  const isMobile = useMobile();
  const { store, app, metadata } = useMst();
  const [tab, setTab] = useState("details");
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
    const newPath = createPath(getKeyFromUrl(urlParams), "proposals");
    navigate(newPath);
    app.setCurrentUrl(newPath, "proposals");
  };

  let content;
  // If the proposal store has loaded, render the page

  const booth = store.booth!;
  if (store.isLoaded && booth.proposalStore.isLoaded) {
    const proposal: ProposalModelType = booth.proposalStore.proposals.get(
      urlParams.proposalId!
    )!;
    const chosenVote = proposal.results.getMyVote;

    const isActive = proposal.status === "Active";

    const authorMetadata: any = metadata.contactsMap.get(proposal.owner) !=
      null || {
      color: "#000",
    };

    //
    // Set the timer and get timeString
    //
    const { timeString } = descriptiveTimeString(proposal.start, proposal.end);
    const [time, setTime] = useState(timeString);
    let timerId: any = null;
    function timerUpdate() {
      const { timeString, timerInterval } = descriptiveTimeString(
        proposal.start,
        proposal.end
      );
      setTime(timeString);

      if (timerInterval !== null) {
        timerId = setTimeout(() => timerUpdate(), timerInterval);
      }
    }
    useEffect(() => {
      // initial timer
      timerUpdate();
      return function cleanup() {
        // Cleanup the timer on unmount
        clearTimeout(timerId);
      };
    }, []);

    const delegateStore = booth.delegateStore;
    const winningChoice = toJS(
      proposal.choices.find(
        (choice: ChoiceModelType) => proposal.tally?.topChoice === choice.label
      )
    );
    const hasAction = !!(winningChoice?.action && winningChoice?.data != null);

    content = (
      <Grid2.Row reverse={["xs"]} justify="center">
        <Grid2.Column
          {...(isMobile && { noGutter: true })}
          mb="16px"
          md={6}
          lg={9}
          xl={9}
          gap={12}
        >
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
                <Ship
                  textOpacity={0.9}
                  patp={proposal.owner}
                  avatar={authorMetadata?.avatar}
                  nickname={authorMetadata?.nickname}
                  color={authorMetadata?.color || "#000000"}
                  size="small"
                  clickable={false}
                />
                <KPI icon={<TlonIcon icon="Clock" />} value={time} />
              </Flex>
              {/* {proposal.status === "Ended" && (
                  <ProposalResult booth={booth} proposal={proposal} />
                )} */}
              <Flex style={{ gap: 16 }} mt={5} flexDirection="row">
                <Tab
                  active={tab === "details"}
                  onClick={() => setTab("details")}
                >
                  Details
                </Tab>
                <Tab
                  active={tab === "vote-breakdown"}
                  isDisabled={
                    proposal.status !== "Ended" ||
                    proposal.tally?.status === "failed"
                  }
                  onClick={() => setTab("vote-breakdown")}
                >
                  Voters
                </Tab>
              </Flex>
            </DetailHeader>
            {proposal.status === "Ended" && (
              <ProposalResult
                hideBorderBottom={hasAction}
                booth={booth}
                proposal={proposal}
              />
            )}
            {proposal.status === "Ended" && hasAction && (
              <ProposalResultSection
                style={{ fontSize: 14, borderTop: "none", paddingTop: 2 }}
              >
                <ActionDataTable
                  action={winningChoice?.action!}
                  data={winningChoice?.data}
                />
              </ProposalResultSection>
            )}
            {tab === "details" && (
              <>
                <DetailBody>
                  <MDEditor.Markdown
                    style={{
                      padding: 16,
                      borderBottomLeftRadius: 6,
                      borderBottomRightRadius: 6,
                      background: "transparent",
                      fontFamily: "Inter, sans-serif",
                      color: "inherit",
                    }}
                    source={proposal.content}
                    rehypePlugins={[[rehypeSanitize]]}
                  />
                </DetailBody>
              </>
            )}
            {tab === "vote-breakdown" && (
              <>
                {proposal.status === "Ended" && (
                  <Flex p={16}>
                    <VoteResultList votes={proposal.results.votes} />
                  </Flex>
                )}
              </>
            )}
          </Card>
        </Grid2.Column>
        <Grid2.Column gap={12} mb="16px" md={2} lg={3}>
          <Grid2.Row>
            <VoteCard
              style={{ width: "100%" }}
              delegate={delegateStore.delegates.get(app.account.patp)}
              disabled={!isActive}
              choices={proposal.choices}
              title={proposal.title}
              loading={proposal.isVoteLoading}
              currentUser={app.account}
              strategy={proposal.strategy}
              onVote={onVote}
              timeLeft={time}
              votingPower={delegateStore.getVotingPower(app.account.patp)}
              chosenOption={chosenVote && chosenVote.choice}
              voteResults={proposal.results.resultSummary}
              voteSubmitted={proposal.results.didVote}
            />
          </Grid2.Row>
          <Grid2.Row>
            <Card
              padding={12}
              style={{
                width: "100%",
                borderColor: "transparent",
                borderWidth: 0,
              }}
              elevation="lifted"
            >
              <Text fontWeight="600" variant="h6" mb="12px">
                Information
              </Text>
              <Grid2.Column noGutter>
                <Box mb={2} width="100%">
                  <KPI
                    mt={1}
                    inline
                    width="inherit"
                    label="Strategy"
                    value={proposal.strategy}
                  />
                </Box>
                <Box mb={2} width="100%">
                  <KPI
                    inline
                    width="inherit"
                    label="Quorum"
                    value={`${proposal.support}%`}
                  />
                </Box>
                <Box mb={2} width="100%">
                  <KPI
                    inline
                    width="inherit"
                    label="Start date"
                    value={displayDate(proposal.start * 1000)}
                  />
                </Box>
                <Box mb={2} width="100%">
                  <KPI
                    inline
                    width="inherit"
                    label="End date"
                    value={displayDate(proposal.end * 1000)}
                  />
                </Box>
                {/* <Box mb={2} width="100%">
                  <KPI
                    inline
                    width="inherit"
                    label="Created at"
                    value={displayDate(parseInt(proposal.created!))}
                  />
                </Box> */}
                <Box mb={2} width="100%">
                  <KPI
                    inline
                    width="inherit"
                    label="Host"
                    value={proposal.owner}
                  />
                </Box>
              </Grid2.Column>
            </Card>
          </Grid2.Row>
        </Grid2.Column>
      </Grid2.Row>
    );
  }

  return (
    <Grid2.Box offset={40} fluid scroll ref={div}>
      <Grid2.Box {...(isMobile && { p: 0 })}>
        <Grid2.Column
          {...(isMobile && { noGutter: true })}
          mb="16px"
          lg={12}
          xl={12}
        >
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
