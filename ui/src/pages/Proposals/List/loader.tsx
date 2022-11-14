import { observer } from "mobx-react-lite";
import React, { FC, useState } from "react";
import { useParams } from "react-router";

import {
  Button,
  Flex,
  Grid2,
  Label,
  ListHeader,
  OptionType,
  Select,
  Skeleton,
  VirtualizedList,
} from "@holium/design-system";

import { Participants } from "../../../components/Participants";
import { getProposalFilters } from "../../../logic/stores/proposals/utils";
import { useMst } from "../../../logic/stores/root";
import { ProposalType } from "../../../logic/types/proposals";
import { getBoothName } from "../../../logic/utils/metadata";
import { getKeyFromUrl } from "../../../logic/utils/path";
import { useMobile } from "../../../logic/utils/useMobile";

export const ProposalListLoader: FC = observer(() => {
  const [selectedOption, setSelectedOption] = useState("All");
  const urlParams = useParams();
  const isMobile = useMobile();
  const { store } = useMst();

  const currentBoothKey = getKeyFromUrl(urlParams);
  let leftPane;

  const booth = store.booth;
  let proposalsList: any[] = booth?.listProposals!;

  const statusCounts = getProposalFilters(proposalsList);
  if (selectedOption === "All") {
    proposalsList = proposalsList;
  } else {
    proposalsList = proposalsList.filter(
      (proposal: ProposalType) => proposal.status === selectedOption
    );
  }

  leftPane = (
    <Flex
      mb="8px"
      style={{ height: "inherit" }}
      flex={1}
      flexDirection="column"
    >
      <ListHeader
        title="Proposals"
        subtitle={{ text: getBoothName(booth!) }}
        options={[
          {
            label: "All",
            value: "All",
          },
          {
            label: "Upcoming",
            value: "Upcoming",
            disabled: !statusCounts.Upcoming,
          },
          {
            label: "Active",
            value: "Active",
            disabled: !statusCounts.Active,
          },
          {
            label: "Ended",
            value: "Ended",
            disabled: !statusCounts.Ended,
          },
        ]}
        selectedOption={selectedOption}
        rightContent={
          <Button pt="6px" pb="6px" variant="transparent">
            Create proposal
          </Button>
        }
        rightOptions={
          // TODO make responsive
          <Flex style={{ width: 200 }} justifyContent="flex-end" itemsCenter>
            <Select
              small
              leftInteractive={true}
              leftIcon={
                <Label
                  style={{ opacity: 0.7, fontWeight: "normal", width: 50 }}
                >
                  Sort by
                </Label>
              }
              selectionOption={booth!.sortBy}
              options={[
                {
                  label: "Recent",
                  value: "recent",
                },
                {
                  label: "Next ending",
                  value: "ending",
                },
                {
                  label: "Next starting",
                  value: "starting",
                },
              ]}
              onSelected={(option: {
                value: "recent" | "ending" | "starting";
              }) => {
                booth?.setSortBy(option.value);
              }}
            />
          </Flex>
        }
        onSelected={(option: OptionType) => {
          setSelectedOption(option.label);
        }}
      />
      <VirtualizedList
        id={`list-${currentBoothKey}-${new Date().getMilliseconds()}`}
        style={{
          marginTop: 8,
          height: "calc(100% - 12px)",
        }}
        itemHeight={112}
        numItems={3}
        renderItem={({
          key,
          index,
          style,
        }: {
          key: number;
          index: number;
          style: any;
        }) => {
          return (
            <Flex key={key} flexDirection="column" mb="10px">
              <Skeleton
                style={{
                  height: 69,
                  borderRadius: 8,
                  width: "100%",
                }}
              />
              <Skeleton
                style={{
                  marginTop: 6,
                  height: 26,
                  borderRadius: 8,
                  width: "150px",
                }}
              />
            </Flex>
          );
        }}
      />
    </Flex>
  );

  return (
    <Grid2.Box offset={40} fluid scroll>
      <Grid2.Box {...(isMobile && { p: 0 })}>
        <Grid2.Column
          {...(isMobile && { noGutter: true })}
          mt="16px"
          lg={12}
          xl={12}
        >
          <Grid2.Row justify="center">
            <Grid2.Column xs={4} sm={5} md={5} lg={9} xl={9}>
              {leftPane}
            </Grid2.Column>
            <Grid2.Column xs={4} sm={3} md={3} lg={3}>
              <Participants
                loading={true}
                participants={[]}
                onAdd={(patp: string) => {
                  booth!.participantStore.add(patp);
                }}
                onRemove={(patp: string) => {
                  booth!.participantStore.remove(patp);
                }}
              />
            </Grid2.Column>
          </Grid2.Row>
        </Grid2.Column>
      </Grid2.Box>
    </Grid2.Box>
  );
});
// return (
//   <CenteredPane style={{ height: "100%" }} width={1216} bordered={false}>
//     <Grid2.Box>
//       <Grid2.Row>
//         <Grid2.Column>{leftPane}</Grid2.Column>
//         <Grid2.Column>
//           <Flex style={{ width: 300, height: "fit-content" }}>
//             <Participants
//               loading={participantLoading}
//               participants={participants}
//               onAdd={(patp: string) => {
//                 store.booth!.participantStore.add(patp);
//               }}
//               onRemove={(patp: string) => {
//                 store.booth!.participantStore.remove(patp);
//               }}
//             />
//           </Flex>
//         </Grid2.Column>
//       </Grid2.Row>
//     </Grid2.Box>
//     {/* <Grid
// mt={16}
// flex={1}
// style={{ height: "inherit" }}
// gridTemplateColumns="2fr 300px"
// gridColumnGap={16}
//     >
//       {leftPane}
//       <Flex style={{ width: 300, height: "fit-content" }}>
//         <Participants
//           loading={participantLoading}
//           participants={participants}
//           onAdd={(patp: string) => {
//             store.booth!.participantStore.add(patp);
//           }}
//           onRemove={(patp: string) => {
//             store.booth!.participantStore.remove(patp);
//           }}
//         />
//       </Flex>
//     </Grid> */}
//   </CenteredPane>
// );
