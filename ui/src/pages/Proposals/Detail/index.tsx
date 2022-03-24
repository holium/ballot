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
} from "@holium/design-system";
import MDEditor from "@uiw/react-md-editor";
import rehypeSanitize from "rehype-sanitize";
import { useStore } from "../../../logic/store";
import { useNavigate, useParams } from "react-router";
import { toJS } from "mobx";
import { observer } from "mobx-react-lite";
import { VoteCard } from "../../../components/VoteCard";
import { ChoiceType, ProposalType } from "../../../logic/types/proposals";
import { createPath } from "../../../logic/utils/path";
import { descriptiveTimeString } from "../../../logic/utils/time";
import { DetailHeader, DetailCentered, DetailBody } from "./Detail.styles";
import { Status } from "../../../components/Status";

export const ProposalDetail: FC = observer((props: any) => {
  const navigate = useNavigate();
  const urlParams = useParams();
  const { appStore, participantStore, proposalStore, voteStore, shipStore } =
    useStore();
  const [chosenVote, setChosenVote] = useState<Partial<ChoiceType>>({
    label: undefined,
  });
  const currentBooth = urlParams.boothName!;
  useEffect(() => {
    proposalStore.isInitial.get() && proposalStore.initial(currentBooth);
    voteStore.initialVotes(currentBooth, urlParams.proposalId!);
  }, []);

  const [height, setHeight] = useState(null);
  const div = useCallback(
    (node) => {
      if (node !== null) {
        setHeight(node.getBoundingClientRect().height);
      }
    },
    [urlParams.proposalId!]
  );
  console.log("result2 test ", toJS(voteStore.results));

  const onVote = (vote: {
    proposalId: string;
    chosenVote: Partial<ChoiceType>;
  }) => {
    voteStore.castVote(
      proposalStore.boothName!,
      vote.proposalId,
      vote.chosenVote
    );
    setChosenVote(vote.chosenVote);
  };

  const onBack = () => {
    let newPath = createPath(
      {
        name: currentBooth,
        // @ts-ignore
        type: urlParams.type!,
      },
      "proposals"
    );
    navigate(newPath);
    appStore.setCurrentUrl(newPath, "proposals");
  };

  let content;
  // If the proposal store has loaded, render the page

  if (proposalStore.isLoaded.get()) {
    let proposal: ProposalType = proposalStore.getProposal(
      urlParams.boothName!,
      urlParams.proposalId!
    )!;

    const otherVotes = 0; // this should be the total votes submitted
    const participantAmounts =
      participantStore.getParticipantCount(currentBooth);

    const isActive = proposal.status === "Active";

    // TODO implement vote result logic
    const votes = proposal.choices.map((value: ChoiceType) => ({
      label: value.label,
      results:
        value.label === chosenVote.label
          ? ((1 + otherVotes) / participantAmounts) * 100
          : 0,
      action: value.action,
      description: value.description,
    }));

    content = (
      <Grid
        style={{
          width: "inherit",
          height: "inherit",
        }}
        gridTemplateColumns="2fr 300px"
        gridColumnGap={16}
      >
        <Flex flexDirection="column">
          <Card
            padding={0}
            style={{ borderColor: "transparent" }}
            elevation="lifted"
            height="100%"
          >
            <DetailHeader>
              <Flex flex={1} flexDirection="row" justifyContent="space-between">
                <Text variant="h4" fontWeight={600}>
                  {proposal.title}
                </Text>
                <Status status={proposal.status} />
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
            </DetailHeader>
            <DetailBody style={{ height: height! - 150, overflowY: "scroll" }}>
              <MDEditor.Markdown
                style={{
                  padding: 16,
                  height: "initial",
                  fontFamily: "Inter, sans-serif",
                }}
                source={proposal.content}
                rehypePlugins={[[rehypeSanitize]]}
              />
            </DetailBody>
          </Card>
        </Flex>
        <Grid
          gridTemplateRows="auto"
          gridRowGap="16px"
          style={{ height: "fit-content" }}
        >
          <VoteCard
            disabled={!isActive}
            choices={proposal.choices}
            title={proposal.title}
            // loading={args.loading}
            currentUser={shipStore.ship}
            strategy={proposal.strategy}
            onVote={onVote}
            chosenOption={chosenVote.label && chosenVote}
            voteResults={votes}
            voteSubmitted={chosenVote.label}
          />
          {/* <Card
            padding={12}
            style={{ borderColor: "transparent" }}
            elevation="lifted"
            height="fit-content"
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
          </Card> */}
        </Grid>
      </Grid>
    );
  }

  return (
    <Fill ref={div}>
      <BreadcrumbNav
        onBack={onBack}
        crumbs={[{ label: "Proposals", onClick: onBack }, { label: "Details" }]}
      />
      <DetailCentered>{content}</DetailCentered>
    </Fill>
  );
});
export default ProposalDetail;
