import React, { FC, useEffect, useState, useMemo } from "react";
import { toJS } from "mobx";
import { useNavigate, useParams } from "react-router";
import { observer } from "mobx-react-lite";

import {
  ListHeader,
  OptionType,
  CenteredPane,
  VirtualizedList,
  Text,
  Flex,
  Grid,
  Button,
} from "@holium/design-system";

import { ProposalType } from "../../../logic/types/proposals";
import { appName } from "../../../app";
import { ProposalCard } from "../../../components/ProposalCard";
import { Participants } from "../../../components/Participants";
import { createPath } from "../../../logic/utils/path";
import { useMst } from "../../../logic/stores/root";
import { ProposalModelType } from "../../../logic/stores/proposals";
import { getProposalFilters } from "../../../logic/stores/proposals/utils";

export const ProposalList: FC = observer(() => {
  const [selectedOption, setSelectedOption] = useState("All");
  const navigate = useNavigate();
  const urlParams = useParams();
  const { store } = useMst();
  const currentBooth = urlParams.boothName!;

  let leftPane;

  // leftPane = useMemo(() => {
  let proposalsList: any[] = store.booth?.listProposals!;

  const hasAdmin = store.booth?.hasAdmin;
  const statusCounts = getProposalFilters(proposalsList);
  if (selectedOption === "All") {
    proposalsList = proposalsList;
  } else {
    proposalsList = proposalsList.filter(
      (proposal: ProposalType) => proposal.status === selectedOption
    );
  }

  const options = [
    {
      label: "All",
      value: "All",
    },
    {
      label: "Upcoming",
      value: "Upcoming",
      disabled: statusCounts["Upcoming"] ? false : true,
    },
    {
      label: "Active",
      value: "Active",
      disabled: statusCounts["Active"] ? false : true,
    },
    {
      label: "Ended",
      value: "Ended",
      disabled: statusCounts["Ended"] ? false : true,
    },
  ];

  // return (
  leftPane = (
    <Flex mb={8} style={{ height: "inherit" }} flex={1} flexDirection="column">
      <ListHeader
        title="Proposals"
        subtitle={{ patp: true, text: currentBooth }}
        options={options}
        selectedOption={selectedOption}
        rightContent={
          // @ts-ignore
          hasAdmin && (
            <Button
              pt="6px"
              pb="6px"
              variant="transparent"
              onClick={() => {
                navigate(
                  `/apps/${appName}/booth/${store.booth?.type}/${currentBooth}/proposals/create-new`
                );
              }}
            >
              Create proposal
            </Button>
          )
        }
        onSelected={(option: OptionType) => {
          setSelectedOption(option.label);
        }}
      />
      {proposalsList?.length ? (
        <VirtualizedList
          id={`list-${currentBooth}-${new Date().getMilliseconds()}`}
          style={{
            marginTop: 12,
            height: "calc(100% - 12px)",
          }}
          itemHeight={112}
          numItems={proposalsList.length}
          renderItem={({
            key,
            index,
            style,
          }: {
            key: number;
            index: number;
            style: any;
          }) => {
            const proposal: ProposalModelType = proposalsList[index];
            return (
              <ProposalCard
                key={key}
                proposal={proposal}
                onClick={(proposal: ProposalModelType) => {
                  let newPath = createPath(
                    store.booth!,
                    "proposals",
                    proposal.key
                  );
                  navigate(newPath);
                }}
                status={proposal.status}
                entity={store.booth!.type}
                contextMenu={[
                  {
                    label: "Copy link",
                    onClick: (event: React.MouseEvent<HTMLElement>) => {
                      event.stopPropagation();
                      console.log("add copy and pasted link");
                    },
                  },
                  {
                    label: "Edit",
                    disabled:
                      proposal.status === "Active" ||
                      proposal.status === "Ended" ||
                      !hasAdmin,
                    // TODO add disabled text
                    onClick: (event: React.MouseEvent<HTMLElement>) => {
                      event.stopPropagation();
                      const proposalStore = store.booth?.proposalStore!;
                      proposalStore.setActive(proposal!);
                      let newPath = createPath(
                        store.booth!,
                        "proposals/editor",
                        proposal.key
                      );
                      navigate(newPath);
                    },
                  },
                  {
                    label: "Delete",
                    intent: "alert",
                    disabled: !hasAdmin || proposal.status === "Active",
                    section: 2,
                    onClick: (event: React.MouseEvent<HTMLElement>) => {
                      event.stopPropagation();
                      const proposalStore = store.booth?.proposalStore!;
                      proposalStore.proposals.delete(proposal.key);
                    },
                  },
                ]}
              />
            );
          }}
        />
      ) : (
        <Text
          variant="body"
          style={{
            opacity: 0.6,
            height: 110,
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
          }}
        >
          No proposals
        </Text>
      )}
    </Flex>
  );
  // }, [currentBooth, store.booth?.proposals, selectedOption]);

  const participants = store.booth ? store.booth.listParticipants : [];
  const participantLoading = store.booth
    ? store.booth.participantStore.isLoading
    : false;
  return (
    <CenteredPane style={{ height: "100%" }} width={1216} bordered={false}>
      <Grid
        mt={16}
        flex={1}
        style={{ height: "inherit" }}
        gridTemplateColumns="2fr 300px"
        gridColumnGap={16}
      >
        {leftPane}
        <Flex style={{ width: 300, height: "fit-content" }}>
          <Participants
            loading={participantLoading}
            participants={participants}
            onAdd={(patp: string) => {
              store.booth!.participantStore.add(patp);
            }}
            onRemove={(patp: string) => {
              store.booth!.participantStore.remove(patp);
            }}
          />
        </Flex>
      </Grid>
    </CenteredPane>
  );
});
