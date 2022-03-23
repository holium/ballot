import React from "react";
import styled, { css } from "styled-components";
import {
  TextButton,
  theme,
  AppButton,
  Icons,
  Flex,
  Text,
} from "@holium/design-system";

export interface Props {
  page: number;
  totalPages: number;
  handlePagination: (page: number) => void;
}

type PageButtonProps = {
  active: boolean;
};

const PageButton = styled(TextButton)`
  ${(props: PageButtonProps) =>
    props.active === true &&
    css`
      opacity: 1; /* correct opacity on iOS */
      color: #fff;
      background-color: ${(props) => props.theme.colors.brand.primary};
      border-color: ${(props) => props.theme.colors.brand.primary};
      pointer-events: none;
    `}
`;

export const PaginationComponent: React.FC<Props> = ({
  page,
  totalPages,
  handlePagination,
}) => {
  return (
    <Flex
      flexDirection="row"
      justifyContent="space-between"
      m={2}
      width={["180px", "320px", "620px"]}
    >
      {page !== 1 && (
        <AppButton
          name="Back"
          icon={<Icons.ArrowLeft />}
          expanded={false}
          disabled={false}
          selected={false}
          tooltip={false}
          onAppClick={() => handlePagination(page - 1)}
        />
      )}

      <Flex
        flexDirection="row"
        justifyContent="center"
        alignItems="center"
        gap={4}
      >
        {page === 1 ? (
          <PageButton onClick={() => handlePagination(1)} active={true}>
            {page}
          </PageButton>
        ) : (
          <TextButton onClick={() => handlePagination(1)}>1</TextButton>
        )}
        {page > 3 && (
          <AppButton
            name="Ellipsis"
            icon={<Icons.Ellipsis />}
            expanded={false}
            disabled={true}
            selected={false}
            tooltip={false}
            onAppClick={() => {}}
          />
        )}
        {page === totalPages && totalPages > 3 && (
          <TextButton onClick={() => handlePagination(page - 2)}>
            {page - 2}
          </TextButton>
        )}
        {page > 2 && (
          <TextButton onClick={() => handlePagination(page - 1)}>
            {page - 1}
          </TextButton>
        )}
        {page !== 1 && page !== totalPages && (
          <PageButton onClick={() => handlePagination(page)} active={true}>
            {page}
          </PageButton>
        )}
        {page < totalPages - 1 && (
          <TextButton onClick={() => handlePagination(page + 1)}>
            {page + 1}
          </TextButton>
        )}
        {page === 1 && totalPages > 3 && (
          <TextButton onClick={() => handlePagination(page + 2)}>
            {page + 2}
          </TextButton>
        )}
        {page < totalPages - 2 && (
          <AppButton
            name="Ellipsis"
            icon={<Icons.Ellipsis />}
            expanded={false}
            disabled={true}
            selected={false}
            tooltip={false}
            onAppClick={() => {}}
          />
        )}
        {page === totalPages ? (
          <PageButton
            onClick={() => handlePagination(totalPages)}
            active={true}
          >
            {totalPages}
          </PageButton>
        ) : (
          <TextButton onClick={() => handlePagination(totalPages)}>
            {totalPages}
          </TextButton>
        )}
      </Flex>
      {page !== totalPages && (
        <AppButton
          name="More pages"
          icon={<Icons.ArrowRight />}
          expanded={false}
          disabled={false}
          tooltip={false}
          selected={false}
          onAppClick={() => handlePagination(page + 1)}
        />
      )}
    </Flex>
  );
};
export const Pagination = PaginationComponent;
