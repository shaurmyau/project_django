--
-- PostgreSQL database dump
--

\restrict poKBtu3Z3zYyy0ZjSUDCSVcJdWv1emRQfUIStfZwqFIGDyXQJbfu3LUg688Kj3r

-- Dumped from database version 14.20 (Ubuntu 14.20-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.20 (Ubuntu 14.20-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: project_2; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE project_2 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';


ALTER DATABASE project_2 OWNER TO postgres;

\unrestrict poKBtu3Z3zYyy0ZjSUDCSVcJdWv1emRQfUIStfZwqFIGDyXQJbfu3LUg688Kj3r
\connect project_2
\restrict poKBtu3Z3zYyy0ZjSUDCSVcJdWv1emRQfUIStfZwqFIGDyXQJbfu3LUg688Kj3r

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: _pgtrigger_should_ignore(name); Type: FUNCTION; Schema: public; Owner: zahar
--

CREATE FUNCTION public._pgtrigger_should_ignore(trigger_name name) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
                DECLARE
                    _pgtrigger_ignore TEXT[];
                    _result BOOLEAN;
                BEGIN
                    BEGIN
                        SELECT INTO _pgtrigger_ignore
                            CURRENT_SETTING('pgtrigger.ignore');
                        EXCEPTION WHEN OTHERS THEN
                    END;
                    IF _pgtrigger_ignore IS NOT NULL THEN
                        SELECT trigger_name = ANY(_pgtrigger_ignore)
                        INTO _result;
                        RETURN _result;
                    ELSE
                        RETURN FALSE;
                    END IF;
                END;
            $$;


ALTER FUNCTION public._pgtrigger_should_ignore(trigger_name name) OWNER TO zahar;

--
-- Name: pgtrigger_update_balance_on_delete_64d52(); Type: FUNCTION; Schema: public; Owner: zahar
--

CREATE FUNCTION public.pgtrigger_update_balance_on_delete_64d52() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                
                BEGIN
                    IF ("public"._pgtrigger_should_ignore(TG_NAME) IS TRUE) THEN
                        IF (TG_OP = 'DELETE') THEN
                            RETURN OLD;
                        ELSE
                            RETURN NEW;
                        END IF;
                    END IF;
                    
                    BEGIN
                        -- Возвращаем деньги при удалении транзакции
                        IF OLD.dir THEN
                            -- Удаляем доход - отнимаем деньги
                            UPDATE main_balance 
                            SET bal = bal - OLD.amount 
                            WHERE id = OLD.bal_id;
                        ELSE
                            -- Удаляем расход - возвращаем деньги
                            UPDATE main_balance 
                            SET bal = bal + OLD.amount 
                            WHERE id = OLD.bal_id;
                        END IF;
                        RETURN OLD;
                    END;
                
                END;
            $$;


ALTER FUNCTION public.pgtrigger_update_balance_on_delete_64d52() OWNER TO zahar;

--
-- Name: pgtrigger_update_balance_on_insert_e76ab(); Type: FUNCTION; Schema: public; Owner: zahar
--

CREATE FUNCTION public.pgtrigger_update_balance_on_insert_e76ab() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                
                BEGIN
                    IF ("public"._pgtrigger_should_ignore(TG_NAME) IS TRUE) THEN
                        IF (TG_OP = 'DELETE') THEN
                            RETURN OLD;
                        ELSE
                            RETURN NEW;
                        END IF;
                    END IF;
                    
                    BEGIN
                        IF NEW.dir THEN
                            -- Если dir = True (доход), прибавляем деньги
                            UPDATE main_balance 
                            SET bal = bal + NEW.amount 
                            WHERE id = NEW.bal_id;
                        ELSE
                            -- Если dir = False (расход), проверяем баланс и отнимаем деньги
                            DECLARE
                                current_balance INTEGER;
                            BEGIN
                                SELECT bal INTO current_balance 
                                FROM main_balance 
                                WHERE id = NEW.bal_id
                                FOR UPDATE;
                                
                                IF current_balance >= NEW.amount THEN
                                    UPDATE main_balance 
                                    SET bal = bal - NEW.amount 
                                    WHERE id = NEW.bal_id;
                                ELSE
                                    RAISE EXCEPTION 'Недостаточно средств на счету. Доступно: %, требуется: %', 
                                    current_balance, NEW.amount;
                                END IF;
                            END;
                        END IF;
                        RETURN NEW;
                    END;
                
                END;
            $$;


ALTER FUNCTION public.pgtrigger_update_balance_on_insert_e76ab() OWNER TO zahar;

--
-- Name: pgtrigger_update_balance_on_update_856d1(); Type: FUNCTION; Schema: public; Owner: zahar
--

CREATE FUNCTION public.pgtrigger_update_balance_on_update_856d1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                
                BEGIN
                    IF ("public"._pgtrigger_should_ignore(TG_NAME) IS TRUE) THEN
                        IF (TG_OP = 'DELETE') THEN
                            RETURN OLD;
                        ELSE
                            RETURN NEW;
                        END IF;
                    END IF;
                    
                    BEGIN
                        -- Сначала возвращаем старые деньги
                        IF OLD.dir THEN
                            -- Старая транзакция была доходом - отнимаем
                            UPDATE main_balance 
                            SET bal = bal - OLD.amount 
                            WHERE id = OLD.bal_id;
                        ELSE
                            -- Старая транзакция была расходом - возвращаем
                            UPDATE main_balance 
                            SET bal = bal + OLD.amount 
                            WHERE id = OLD.bal_id;
                        END IF;
                        
                        -- Затем применяем новые значения
                        IF NEW.dir THEN
                            -- Новая транзакция - доход, прибавляем
                            UPDATE main_balance 
                            SET bal = bal + NEW.amount 
                            WHERE id = NEW.bal_id;
                        ELSE
                            -- Новая транзакция - расход, проверяем баланс
                            DECLARE
                                current_balance INTEGER;
                            BEGIN
                                SELECT bal INTO current_balance 
                                FROM main_balance 
                                WHERE id = NEW.bal_id
                                FOR UPDATE;
                                
                                IF current_balance >= NEW.amount THEN
                                    UPDATE main_balance 
                                    SET bal = bal - NEW.amount 
                                    WHERE id = NEW.bal_id;
                                ELSE
                                    -- Возвращаем старые деньги обратно (откатываем первую операцию)
                                    IF OLD.dir THEN
                                        UPDATE main_balance 
                                        SET bal = bal + OLD.amount 
                                        WHERE id = OLD.bal_id;
                                    ELSE
                                        UPDATE main_balance 
                                        SET bal = bal - OLD.amount 
                                        WHERE id = OLD.bal_id;
                                    END IF;
                                    
                                    RAISE EXCEPTION 'Недостаточно средств на счету после обновления. Требуется: %', 
                                    NEW.amount;
                                END IF;
                            END;
                        END IF;
                        RETURN NEW;
                    END;
                
                END;
            $$;


ALTER FUNCTION public.pgtrigger_update_balance_on_update_856d1() OWNER TO zahar;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO zahar;

--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_id_seq OWNER TO zahar;

--
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO zahar;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_permissions_id_seq OWNER TO zahar;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO zahar;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_permission_id_seq OWNER TO zahar;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


ALTER TABLE public.auth_user OWNER TO zahar;

--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.auth_user_groups OWNER TO zahar;

--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_groups_id_seq OWNER TO zahar;

--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.auth_user_groups_id_seq OWNED BY public.auth_user_groups.id;


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.auth_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_id_seq OWNER TO zahar;

--
-- Name: auth_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.auth_user_id_seq OWNED BY public.auth_user.id;


--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_user_user_permissions OWNER TO zahar;

--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_user_permissions_id_seq OWNER TO zahar;

--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.auth_user_user_permissions_id_seq OWNED BY public.auth_user_user_permissions.id;


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO zahar;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.django_admin_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_admin_log_id_seq OWNER TO zahar;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO zahar;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.django_content_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_content_type_id_seq OWNER TO zahar;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO zahar;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

CREATE SEQUENCE public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_migrations_id_seq OWNER TO zahar;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zahar
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO zahar;

--
-- Name: main_balance; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_balance (
    id bigint NOT NULL,
    bal integer NOT NULL,
    owner_id integer NOT NULL,
    CONSTRAINT main_balance_bal_check CHECK ((bal >= 0))
);


ALTER TABLE public.main_balance OWNER TO zahar;

--
-- Name: main_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_balance ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_balance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_budget; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_budget (
    id bigint NOT NULL,
    "limit" integer NOT NULL,
    bal_id bigint NOT NULL,
    category_id bigint NOT NULL,
    CONSTRAINT main_budget_limit_check CHECK (("limit" >= 0))
);


ALTER TABLE public.main_budget OWNER TO zahar;

--
-- Name: main_budget_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_budget ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_card; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_card (
    id bigint NOT NULL,
    number character varying NOT NULL,
    "CVV" integer NOT NULL,
    date timestamp with time zone NOT NULL,
    bal_id bigint NOT NULL,
    CONSTRAINT "main_card_CVV_check" CHECK (("CVV" >= 0))
);


ALTER TABLE public.main_card OWNER TO zahar;

--
-- Name: main_card_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_card ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_card_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_category; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_category (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.main_category OWNER TO zahar;

--
-- Name: main_category_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_category ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_historicalbalance; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_historicalbalance (
    id bigint NOT NULL,
    bal integer NOT NULL,
    history_id integer NOT NULL,
    history_date timestamp with time zone NOT NULL,
    history_change_reason character varying(100),
    history_type character varying(1) NOT NULL,
    history_user_id integer,
    owner_id integer,
    CONSTRAINT main_historicalbalance_bal_check CHECK ((bal >= 0))
);


ALTER TABLE public.main_historicalbalance OWNER TO zahar;

--
-- Name: main_historicalbalance_history_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_historicalbalance ALTER COLUMN history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_historicalbalance_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_historicalbudget; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_historicalbudget (
    id bigint NOT NULL,
    "limit" integer NOT NULL,
    history_id integer NOT NULL,
    history_date timestamp with time zone NOT NULL,
    history_change_reason character varying(100),
    history_type character varying(1) NOT NULL,
    bal_id bigint,
    category_id bigint,
    history_user_id integer,
    CONSTRAINT main_historicalbudget_limit_check CHECK (("limit" >= 0))
);


ALTER TABLE public.main_historicalbudget OWNER TO zahar;

--
-- Name: main_historicalbudget_history_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_historicalbudget ALTER COLUMN history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_historicalbudget_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_historicalcard; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_historicalcard (
    id bigint NOT NULL,
    number character varying NOT NULL,
    "CVV" integer NOT NULL,
    date timestamp with time zone NOT NULL,
    history_id integer NOT NULL,
    history_date timestamp with time zone NOT NULL,
    history_change_reason character varying(100),
    history_type character varying(1) NOT NULL,
    bal_id bigint,
    history_user_id integer,
    CONSTRAINT "main_historicalcard_CVV_check" CHECK (("CVV" >= 0))
);


ALTER TABLE public.main_historicalcard OWNER TO zahar;

--
-- Name: main_historicalcard_history_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_historicalcard ALTER COLUMN history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_historicalcard_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_historicalcategory; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_historicalcategory (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    history_id integer NOT NULL,
    history_date timestamp with time zone NOT NULL,
    history_change_reason character varying(100),
    history_type character varying(1) NOT NULL,
    history_user_id integer
);


ALTER TABLE public.main_historicalcategory OWNER TO zahar;

--
-- Name: main_historicalcategory_history_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_historicalcategory ALTER COLUMN history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_historicalcategory_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_historicalnews; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_historicalnews (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    description text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_published boolean NOT NULL,
    image text,
    history_id integer NOT NULL,
    history_date timestamp with time zone NOT NULL,
    history_change_reason character varying(100),
    history_type character varying(1) NOT NULL,
    history_user_id integer
);


ALTER TABLE public.main_historicalnews OWNER TO zahar;

--
-- Name: main_historicalnews_history_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_historicalnews ALTER COLUMN history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_historicalnews_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_historicaltransactions; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_historicaltransactions (
    id bigint NOT NULL,
    amount integer NOT NULL,
    dir boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    history_id integer NOT NULL,
    history_date timestamp with time zone NOT NULL,
    history_change_reason character varying(100),
    history_type character varying(1) NOT NULL,
    bal_id bigint,
    category_id bigint,
    history_user_id integer,
    CONSTRAINT main_historicaltransactions_amount_check CHECK ((amount >= 0))
);


ALTER TABLE public.main_historicaltransactions OWNER TO zahar;

--
-- Name: main_historicaltransactions_history_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_historicaltransactions ALTER COLUMN history_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_historicaltransactions_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_news; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_news (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    description text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_published boolean NOT NULL,
    image character varying(100)
);


ALTER TABLE public.main_news OWNER TO zahar;

--
-- Name: main_news_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_news ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: main_transactions; Type: TABLE; Schema: public; Owner: zahar
--

CREATE TABLE public.main_transactions (
    id bigint NOT NULL,
    amount integer NOT NULL,
    dir boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    bal_id bigint NOT NULL,
    category_id bigint NOT NULL,
    CONSTRAINT main_transactions_amount_check CHECK ((amount >= 0))
);


ALTER TABLE public.main_transactions OWNER TO zahar;

--
-- Name: main_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: zahar
--

ALTER TABLE public.main_transactions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.main_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: vw_user_transactions; Type: VIEW; Schema: public; Owner: zahar
--

CREATE VIEW public.vw_user_transactions AS
 SELECT row_number() OVER (ORDER BY t.created_at DESC) AS id,
    t.id AS transaction_id,
    card.number AS card_number,
    t.amount,
    t.dir AS amount_direction,
    t.created_at,
    c.name AS category_name
   FROM ((((public.main_transactions t
     JOIN public.main_balance b ON ((t.bal_id = b.id)))
     JOIN public.auth_user u ON ((b.owner_id = u.id)))
     LEFT JOIN public.main_card card ON ((card.bal_id = b.id)))
     LEFT JOIN public.main_category c ON ((t.category_id = c.id)));


ALTER TABLE public.vw_user_transactions OWNER TO zahar;

--
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- Name: auth_group_permissions id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);


--
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- Name: auth_user id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user ALTER COLUMN id SET DEFAULT nextval('public.auth_user_id_seq'::regclass);


--
-- Name: auth_user_groups id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_groups ALTER COLUMN id SET DEFAULT nextval('public.auth_user_groups_id_seq'::regclass);


--
-- Name: auth_user_user_permissions id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_user_user_permissions_id_seq'::regclass);


--
-- Name: django_admin_log id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);


--
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	1	add_logentry
2	Can change log entry	1	change_logentry
3	Can delete log entry	1	delete_logentry
4	Can view log entry	1	view_logentry
5	Can add permission	2	add_permission
6	Can change permission	2	change_permission
7	Can delete permission	2	delete_permission
8	Can view permission	2	view_permission
9	Can add group	3	add_group
10	Can change group	3	change_group
11	Can delete group	3	delete_group
12	Can view group	3	view_group
13	Can add user	4	add_user
14	Can change user	4	change_user
15	Can delete user	4	delete_user
16	Can view user	4	view_user
17	Can add content type	5	add_contenttype
18	Can change content type	5	change_contenttype
19	Can delete content type	5	delete_contenttype
20	Can view content type	5	view_contenttype
21	Can add session	6	add_session
22	Can change session	6	change_session
23	Can delete session	6	delete_session
24	Can view session	6	view_session
25	Can add Категория	7	add_category
26	Can change Категория	7	change_category
27	Can delete Категория	7	delete_category
28	Can view Категория	7	view_category
29	Can add transactions	8	add_transactions
30	Can change transactions	8	change_transactions
31	Can delete transactions	8	delete_transactions
32	Can view transactions	8	view_transactions
33	Can add budget	9	add_budget
34	Can change budget	9	change_budget
35	Can delete budget	9	delete_budget
36	Can view budget	9	view_budget
37	Can add balance	10	add_balance
38	Can change balance	10	change_balance
39	Can delete balance	10	delete_balance
40	Can view balance	10	view_balance
41	Can add card	11	add_card
42	Can change card	11	change_card
43	Can delete card	11	delete_card
44	Can view card	11	view_card
45	Can add user transaction view	12	add_usertransactionview
46	Can change user transaction view	12	change_usertransactionview
47	Can delete user transaction view	12	delete_usertransactionview
48	Can view user transaction view	12	view_usertransactionview
49	Can add Новость	13	add_news
50	Can change Новость	13	change_news
51	Can delete Новость	13	delete_news
52	Can view Новость	13	view_news
53	Can add historical Транзакция	14	add_historicaltransactions
54	Can change historical Транзакция	14	change_historicaltransactions
55	Can delete historical Транзакция	14	delete_historicaltransactions
56	Can view historical Транзакция	14	view_historicaltransactions
57	Can add historical Новость	15	add_historicalnews
58	Can change historical Новость	15	change_historicalnews
59	Can delete historical Новость	15	delete_historicalnews
60	Can view historical Новость	15	view_historicalnews
61	Can add historical Категория	16	add_historicalcategory
62	Can change historical Категория	16	change_historicalcategory
63	Can delete historical Категория	16	delete_historicalcategory
64	Can view historical Категория	16	view_historicalcategory
65	Can add historical Ограничение бюжета	17	add_historicalbudget
66	Can change historical Ограничение бюжета	17	change_historicalbudget
67	Can delete historical Ограничение бюжета	17	delete_historicalbudget
68	Can view historical Ограничение бюжета	17	view_historicalbudget
69	Can add historical Карта	18	add_historicalcard
70	Can change historical Карта	18	change_historicalcard
71	Can delete historical Карта	18	delete_historicalcard
72	Can view historical Карта	18	view_historicalcard
73	Can add historical Баланс	19	add_historicalbalance
74	Can change historical Баланс	19	change_historicalbalance
75	Can delete historical Баланс	19	delete_historicalbalance
76	Can view historical Баланс	19	view_historicalbalance
\.


--
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) FROM stdin;
11	pbkdf2_sha256$1000000$U0ddUNLsjf32f9JXA8Awmz$PGZxW7VYNISoAzBB0RaxN8m2wvw7rN/ntL7x4e2LcHg=	2025-12-24 17:28:26.60896+03	f	guest1			n@mail.ru	f	t	2025-12-24 17:28:25.985746+03
2	pbkdf2_sha256$1000000$ipDx0n4k1xMF9R5WYk8kxA$2Cy7Rre6Tjhjfm4pq6jcY5VpvxGghvn7TVf5S6ZNEUs=	2025-12-25 01:18:48.45043+03	t	zahar			zaharcekunkov@gmail.com	t	t	2025-11-27 14:57:18.346261+03
10	pbkdf2_sha256$1000000$8j6vh77vHHLwionOrLr7n4$m9hu44gfGeIrU3ZpZsmm6fGt0jrGVIWlIwmp+aux0qU=	2025-12-25 01:19:02.674449+03	f	guest			abc@mail.ru	f	t	2025-12-09 15:17:10.292763+03
\.


--
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.auth_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.auth_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
1	2025-12-04 14:24:00.137762+03	1	2585	3		4	2
2	2025-12-04 14:24:00.142842+03	3	guest	3		4	2
3	2025-12-04 14:24:00.146092+03	4	guest1	3		4	2
4	2025-12-04 14:40:53.833184+03	5	guest	3		4	2
5	2025-12-04 14:40:53.839172+03	6	guest1	3		4	2
6	2025-12-04 14:40:53.843905+03	7	guest2	3		4	2
7	2025-12-04 14:40:53.84841+03	8	guest3	3		4	2
8	2025-12-04 14:40:53.851465+03	9	guest4	3		4	2
9	2025-12-12 11:42:49.823616+03	1	Balance object (1)	1	[{"added": {}}]	10	2
10	2025-12-12 12:04:15.090897+03	1	Balance object (1)	1	[{"added": {}}]	10	2
11	2025-12-12 12:04:25.044139+03	2	Balance object (2)	1	[{"added": {}}]	10	2
12	2025-12-12 12:04:37.811594+03	3	Balance object (3)	1	[{"added": {}}]	10	2
13	2025-12-12 12:08:42.016691+03	1	Card object (1)	1	[{"added": {}}]	11	2
14	2025-12-12 12:08:50.994247+03	2	Card object (2)	1	[{"added": {}}]	11	2
15	2025-12-12 12:09:11.193833+03	3	Card object (3)	1	[{"added": {}}]	11	2
16	2025-12-12 12:44:17.185442+03	1	Поступление	1	[{"added": {}}]	7	2
17	2025-12-12 12:44:24.144574+03	2	Снятие денег	1	[{"added": {}}]	7	2
18	2025-12-12 12:44:33.837531+03	3	Развлечения	1	[{"added": {}}]	7	2
19	2025-12-12 12:44:45.885657+03	4	Продуктовые магазины	1	[{"added": {}}]	7	2
20	2025-12-12 12:45:00.191581+03	5	Магазины одежды	1	[{"added": {}}]	7	2
21	2025-12-12 12:45:20.213716+03	6	Интернет и мобильная связи	1	[{"added": {}}]	7	2
22	2025-12-12 12:45:37.33342+03	7	Интернет-магазины	1	[{"added": {}}]	7	2
23	2025-12-12 12:45:57.339877+03	8	Стройматериалы	1	[{"added": {}}]	7	2
24	2025-12-12 12:50:58.150921+03	1	Transactions object (1)	1	[{"added": {}}]	8	2
25	2025-12-12 12:51:11.225427+03	1	Transactions object (1)	2	[{"changed": {"fields": ["\\u041d\\u0430\\u043f\\u0440\\u0430\\u0432\\u043b\\u0435\\u043d\\u0438\\u0435"]}}]	8	2
26	2025-12-18 14:17:24.64264+03	7	Transactions object (7)	3		8	2
27	2025-12-18 14:17:24.642672+03	6	Transactions object (6)	3		8	2
28	2025-12-18 14:49:33.113953+03	1	Спонсорство	1	[{"added": {}}]	13	2
29	2025-12-18 14:52:02.179708+03	2	Мы открылись	1	[{"added": {}}]	13	2
30	2025-12-18 14:52:32.334148+03	1	Спонсорство	2	[{"changed": {"fields": ["\\u0418\\u0437\\u043e\\u0431\\u0440\\u0430\\u0436\\u0435\\u043d\\u0438\\u0435"]}}]	13	2
31	2025-12-18 14:53:05.464416+03	1	Спонсорство	2	[{"changed": {"fields": ["\\u0418\\u0437\\u043e\\u0431\\u0440\\u0430\\u0436\\u0435\\u043d\\u0438\\u0435"]}}]	13	2
32	2025-12-18 14:58:05.812723+03	2	Мы открылись	2	[{"changed": {"fields": ["\\u0418\\u0437\\u043e\\u0431\\u0440\\u0430\\u0436\\u0435\\u043d\\u0438\\u0435"]}}]	13	2
33	2025-12-18 14:59:33.211202+03	2	Мы открылись	2	[{"changed": {"fields": ["\\u0418\\u0437\\u043e\\u0431\\u0440\\u0430\\u0436\\u0435\\u043d\\u0438\\u0435"]}}]	13	2
34	2025-12-18 14:59:41.819297+03	1	Спонсорство	2	[{"changed": {"fields": ["\\u0418\\u0437\\u043e\\u0431\\u0440\\u0430\\u0436\\u0435\\u043d\\u0438\\u0435"]}}]	13	2
35	2025-12-22 23:02:06.669812+03	13	Transactions object (13)	2	[{"changed": {"fields": ["\\u041a\\u043e\\u043b-\\u0432\\u043e \\u0434\\u0435\\u043d\\u0435\\u0433"]}}]	8	2
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	permission
3	auth	group
4	auth	user
5	contenttypes	contenttype
6	sessions	session
7	main	category
8	main	transactions
9	main	budget
10	main	balance
11	main	card
12	main	usertransactionview
13	main	news
14	main	historicaltransactions
15	main	historicalnews
16	main	historicalcategory
17	main	historicalbudget
18	main	historicalcard
19	main	historicalbalance
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2025-11-27 14:43:22.62631+03
2	auth	0001_initial	2025-11-27 14:43:22.729642+03
3	admin	0001_initial	2025-11-27 14:43:22.761008+03
4	admin	0002_logentry_remove_auto_add	2025-11-27 14:43:22.769822+03
5	admin	0003_logentry_add_action_flag_choices	2025-11-27 14:43:22.777531+03
6	contenttypes	0002_remove_content_type_name	2025-11-27 14:43:22.790833+03
7	auth	0002_alter_permission_name_max_length	2025-11-27 14:43:22.799314+03
8	auth	0003_alter_user_email_max_length	2025-11-27 14:43:22.808395+03
9	auth	0004_alter_user_username_opts	2025-11-27 14:43:22.816579+03
10	auth	0005_alter_user_last_login_null	2025-11-27 14:43:22.824979+03
11	auth	0006_require_contenttypes_0002	2025-11-27 14:43:22.828561+03
12	auth	0007_alter_validators_add_error_messages	2025-11-27 14:43:22.837934+03
13	auth	0008_alter_user_username_max_length	2025-11-27 14:43:22.850815+03
14	auth	0009_alter_user_last_name_max_length	2025-11-27 14:43:22.859249+03
15	auth	0010_alter_group_name_max_length	2025-11-27 14:43:22.867828+03
16	auth	0011_update_proxy_permissions	2025-11-27 14:43:22.875341+03
17	auth	0012_alter_user_first_name_max_length	2025-11-27 14:43:22.883433+03
18	sessions	0001_initial	2025-11-27 14:43:22.907526+03
19	main	0001_initial	2025-12-05 10:38:15.903748+03
20	main	0002_balance_budget_card_transactions	2025-12-05 11:03:07.391978+03
21	main	0003_auto_20251205_0809	2025-12-05 11:09:28.041724+03
22	main	0004_alter_card_date	2025-12-05 11:20:53.02399+03
23	main	0005_auto_20251205_0834	2025-12-05 11:34:32.693629+03
24	main	0006_auto_20251205_0843	2025-12-05 11:43:36.705371+03
25	main	0007_alter_card_date	2025-12-09 15:16:34.894868+03
26	main	0002_alter_card_date	2025-12-09 16:06:44.441606+03
27	main	0003_alter_card_date	2025-12-09 16:07:18.473339+03
28	main	0005_remove_card_owner	2025-12-12 09:19:47.897065+03
29	main	0002_fix_missing_owner	2025-12-12 10:04:12.62597+03
30	main	0002_category_balance_card_budget_transactions_and_more	2025-12-12 11:48:45.22531+03
31	main	0003_alter_balance_options_alter_budget_options_and_more	2025-12-17 10:40:29.816153+03
32	main	0004_news	2025-12-18 14:39:33.349965+03
33	main	0005_historicalbalance_historicalbudget_historicalcard_and_more	2025-12-22 23:00:23.301253+03
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
o79uxxa3d7imoshlpdvm7ayu5y5x4lti	.eJxVjDsOwjAQBe_iGlm24y8lPWewdtcrHEC2FCcV4u4QKQW0b2beS2TY1pq3wUueizgLI06_GwI9uO2g3KHduqTe1mVGuSvyoENee-Hn5XD_DiqM-q0DU4CIaJUxiJ7JBhcnQxzBFPIlmpio-AkndBpA25gYNDpQLqmkgnh_APiuN_k:1vOacv:NUvZyYBfLUeseO_eEB3fKoIQze9GSRI3vuzt7b9sPQs	2025-12-11 14:57:33.625423+03
tfwpqievwf0a5gf90w04znr895q597p6	e30:1vYX6d:_N-StiRD3AwWQKZtgMcXRczFZAlzV2qwph_3MSs8zhc	2026-01-08 01:13:19.17302+03
1qhrt69jyf83os804ak9fb4p71y1xxkq	e30:1vYX7d:YU8K3yaauzJXIL8FVcXOO4F1qskE7uEDbbF8HQnQIYw	2026-01-08 01:14:21.187489+03
18px5urj9cc3oee2cduev52bz43apcac	e30:1vYX7u:8UYMU5N-IF6muElx9vYBHwtEMdjclQ3YJpKz-WR6ZKk	2026-01-08 01:14:38.404888+03
yj93yivlyqa1812ti4102vbjf3cig1bg	.eJxVjEEOgjAURO_StWlaCrZ16Z4zkPn9vxY1kFBYGe-uJCx0O--9eakB21qGrcoyjKwuyhp1-h0J6SHTTviO6TbrNE_rMpLeFX3QqvuZ5Xk93L-Dglq-tU_ctGRA4lLsogRKzhAsKDsECnyGz8EzuCFE6WxuM1y2nUErHLN6fwBCpTnW:1vYXCA:vok4GbxmbPXsmxV6sz76peSACLJ4pnlmLSMZfL1h8Oc	2026-01-08 01:19:02.677848+03
ro6at71wdbqexgbboeefab96b7zikt1q	.eJxVjMsOwiAUBf-FtSFQRHpduu83kPsAqZqSlHZl_HfbpAvdzsw5bxVxXUpcW5rjKOqqrFGnX0jIzzTtRh443avmOi3zSHpP9GGbHqqk1-1o_w4KtrKtuQMr1Hsk8ZIz9HwWI5Qg0yUjkcfOMknKGw2MxkEIxlkM0JEDBvX5AlT3Oa8:1vSwgT:r30fQ-Z3E8n8rZOEeq69VP6Li8lSe6GZpbj-r_DwudE	2025-12-23 15:19:13.761643+03
wxrm27sccxhphgrvxcl59ct9qav37gi6	.eJxVjDsOwyAQRO9CHSE-i4GU6X0GtMA6OIlAMnYV5e6xJRdJN5r3Zt4s4LaWsHVawpzZlSl2-e0ipifVA-QH1nvjqdV1mSM_FH7SzseW6XU73b-Dgr3sa2Gc9lH6SIqESSmqaVLCRMgS9Z4JtBuMApdRC0c4WJAOPORklfY2sc8X3hM3dA:1vTz9P:oJf9KmwqMvGknyuq93R2mtMPMYAuGfexFcESA663D8g	2025-12-26 12:09:23.429095+03
wzm47nmesr63logj92a4y7ucrl4zhzza	.eJxVjDsOwyAQRO9CHSE-i4GU6X0GtMA6OIlAMnYV5e6xJRdJN5r3Zt4s4LaWsHVawpzZlSl2-e0ipifVA-QH1nvjqdV1mSM_FH7SzseW6XU73b-Dgr3sa2Gc9lH6SIqESSmqaVLCRMgS9Z4JtBuMApdRC0c4WJAOPORklfY2sc8X3hM3dA:1vWClH:f1qkDhldhIoRV9MuGlNL72KFx6I__Fwefk5RrYqce08	2026-01-01 15:05:39.478954+03
57g7mwd1maum07iv6g0efico4yh6cx7b	.eJxVjDsOwyAQRO9CHSE-i4GU6X0GtMA6OIlAMnYV5e6xJRdJN5r3Zt4s4LaWsHVawpzZlSl2-e0ipifVA-QH1nvjqdV1mSM_FH7SzseW6XU73b-Dgr3sa2Gc9lH6SIqESSmqaVLCRMgS9Z4JtBuMApdRC0c4WJAOPORklfY2sc8X3hM3dA:1vXyE3:KPMZ6m3PTKlGZm4kQY20W2C7YtBZNsnIwQuMbS2X4NM	2026-01-06 11:58:39.866703+03
\.


--
-- Data for Name: main_balance; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_balance (id, bal, owner_id) FROM stdin;
4	0	2
3	40012	2
2	1100	10
1	4300	2
\.


--
-- Data for Name: main_budget; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_budget (id, "limit", bal_id, category_id) FROM stdin;
4	500	1	2
\.


--
-- Data for Name: main_card; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_card (id, number, "CVV", date, bal_id) FROM stdin;
1	5827 5253 3381 3649	784	2025-12-12 12:08:42.012988+03	1
2	8370 6285 6660 4465	466	2025-12-12 12:08:50.991601+03	3
3	7048 6936 1453 6275	800	2025-12-12 12:09:11.192586+03	2
\.


--
-- Data for Name: main_category; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_category (id, name) FROM stdin;
1	Поступление
2	Снятие денег
3	Развлечения
4	Продуктовые магазины
5	Магазины одежды
6	Интернет и мобильная связи
7	Интернет-магазины
8	Стройматериалы
\.


--
-- Data for Name: main_historicalbalance; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_historicalbalance (id, bal, history_id, history_date, history_change_reason, history_type, history_user_id, owner_id) FROM stdin;
\.


--
-- Data for Name: main_historicalbudget; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_historicalbudget (id, "limit", history_id, history_date, history_change_reason, history_type, bal_id, category_id, history_user_id) FROM stdin;
4	500	1	2025-12-25 01:17:48.060028+03	\N	+	1	2	2
5	500	2	2025-12-25 01:18:02.517898+03	\N	+	2	4	10
3	4000	3	2025-12-25 01:18:57.30746+03	\N	-	3	5	2
5	500	4	2025-12-25 01:19:15.674899+03	\N	-	2	4	10
\.


--
-- Data for Name: main_historicalcard; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_historicalcard (id, number, "CVV", date, history_id, history_date, history_change_reason, history_type, bal_id, history_user_id) FROM stdin;
\.


--
-- Data for Name: main_historicalcategory; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_historicalcategory (id, name, history_id, history_date, history_change_reason, history_type, history_user_id) FROM stdin;
\.


--
-- Data for Name: main_historicalnews; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_historicalnews (id, title, description, created_at, updated_at, is_published, image, history_id, history_date, history_change_reason, history_type, history_user_id) FROM stdin;
\.


--
-- Data for Name: main_historicaltransactions; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_historicaltransactions (id, amount, dir, created_at, history_id, history_date, history_change_reason, history_type, bal_id, category_id, history_user_id) FROM stdin;
14	150	f	2025-12-22 23:01:03.436702+03	1	2025-12-22 23:01:03.446737+03	\N	+	1	2	2
13	500	f	2025-12-18 16:06:45.314171+03	2	2025-12-22 23:02:06.66853+03	\N	~	3	2	2
15	500	t	2025-12-24 17:05:14.936256+03	3	2025-12-24 17:05:14.945756+03	\N	+	2	1	10
17	500	t	2025-12-25 01:12:18.899438+03	4	2025-12-25 01:12:18.904753+03	\N	+	2	1	10
18	200	f	2025-12-25 01:16:10.573568+03	5	2025-12-25 01:16:10.581738+03	\N	+	1	2	2
\.


--
-- Data for Name: main_news; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_news (id, title, description, created_at, updated_at, is_published, image) FROM stdin;
2	Мы открылись	Наш банк начал существовать и открыл свои двери для всех желающих влезть в долги	2025-12-18 14:52:02.178735+03	2025-12-18 14:59:33.209685+03	t	news_images/best-banks-2021-40543452.jpg
1	Спонсорство	Наш банк будет спонсировать университет "Сириус"	2025-12-18 14:49:33.112464+03	2025-12-18 14:59:41.817574+03	t	news_images/1.jpg
\.


--
-- Data for Name: main_transactions; Type: TABLE DATA; Schema: public; Owner: zahar
--

COPY public.main_transactions (id, amount, dir, created_at, bal_id, category_id) FROM stdin;
1	100	f	2025-12-12 12:50:58.148142+03	1	7
2	250	t	2025-12-18 14:05:32.090968+03	1	1
4	15000	t	2025-12-18 14:06:55.929846+03	1	1
5	5000	f	2025-12-18 14:07:07.382808+03	1	7
8	4800	f	2025-12-18 14:18:18.31992+03	1	7
9	500	f	2025-12-18 14:18:39.426147+03	1	7
10	500	f	2025-12-18 14:20:53.959957+03	1	7
11	40000	t	2025-12-18 15:36:49.901057+03	3	1
12	700	f	2025-12-18 15:37:02.799041+03	3	5
14	150	f	2025-12-22 23:01:03.436702+03	1	2
13	500	f	2025-12-18 16:06:45.314171+03	3	2
15	500	t	2025-12-24 17:05:14.936256+03	2	1
17	500	t	2025-12-25 01:12:18.899438+03	2	1
18	200	f	2025-12-25 01:16:10.573568+03	1	2
\.


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 76, true);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 11, true);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 35, true);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 19, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 33, true);


--
-- Name: main_balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_balance_id_seq', 4, true);


--
-- Name: main_budget_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_budget_id_seq', 5, true);


--
-- Name: main_card_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_card_id_seq', 3, true);


--
-- Name: main_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_category_id_seq', 8, true);


--
-- Name: main_historicalbalance_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_historicalbalance_history_id_seq', 1, false);


--
-- Name: main_historicalbudget_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_historicalbudget_history_id_seq', 4, true);


--
-- Name: main_historicalcard_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_historicalcard_history_id_seq', 1, false);


--
-- Name: main_historicalcategory_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_historicalcategory_history_id_seq', 1, false);


--
-- Name: main_historicalnews_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_historicalnews_history_id_seq', 1, false);


--
-- Name: main_historicaltransactions_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_historicaltransactions_history_id_seq', 5, true);


--
-- Name: main_news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_news_id_seq', 2, true);


--
-- Name: main_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zahar
--

SELECT pg_catalog.setval('public.main_transactions_id_seq', 18, true);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: main_balance main_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_balance
    ADD CONSTRAINT main_balance_pkey PRIMARY KEY (id);


--
-- Name: main_budget main_budget_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_budget
    ADD CONSTRAINT main_budget_pkey PRIMARY KEY (id);


--
-- Name: main_card main_card_number_key; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_card
    ADD CONSTRAINT main_card_number_key UNIQUE (number);


--
-- Name: main_card main_card_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_card
    ADD CONSTRAINT main_card_pkey PRIMARY KEY (id);


--
-- Name: main_category main_category_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_category
    ADD CONSTRAINT main_category_pkey PRIMARY KEY (id);


--
-- Name: main_historicalbalance main_historicalbalance_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalbalance
    ADD CONSTRAINT main_historicalbalance_pkey PRIMARY KEY (history_id);


--
-- Name: main_historicalbudget main_historicalbudget_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalbudget
    ADD CONSTRAINT main_historicalbudget_pkey PRIMARY KEY (history_id);


--
-- Name: main_historicalcard main_historicalcard_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalcard
    ADD CONSTRAINT main_historicalcard_pkey PRIMARY KEY (history_id);


--
-- Name: main_historicalcategory main_historicalcategory_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalcategory
    ADD CONSTRAINT main_historicalcategory_pkey PRIMARY KEY (history_id);


--
-- Name: main_historicalnews main_historicalnews_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalnews
    ADD CONSTRAINT main_historicalnews_pkey PRIMARY KEY (history_id);


--
-- Name: main_historicaltransactions main_historicaltransactions_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicaltransactions
    ADD CONSTRAINT main_historicaltransactions_pkey PRIMARY KEY (history_id);


--
-- Name: main_news main_news_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_news
    ADD CONSTRAINT main_news_pkey PRIMARY KEY (id);


--
-- Name: main_transactions main_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_transactions
    ADD CONSTRAINT main_transactions_pkey PRIMARY KEY (id);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: main_balance_owner_id_6e9e9e0d; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_balance_owner_id_6e9e9e0d ON public.main_balance USING btree (owner_id);


--
-- Name: main_budget_bal_id_c703d1f1; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_budget_bal_id_c703d1f1 ON public.main_budget USING btree (bal_id);


--
-- Name: main_budget_category_id_5c3c66d7; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_budget_category_id_5c3c66d7 ON public.main_budget USING btree (category_id);


--
-- Name: main_card_bal_id_9622f74c; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_card_bal_id_9622f74c ON public.main_card USING btree (bal_id);


--
-- Name: main_card_number_c31a2faf_like; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_card_number_c31a2faf_like ON public.main_card USING btree (number varchar_pattern_ops);


--
-- Name: main_historicalbalance_history_date_4de481c0; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbalance_history_date_4de481c0 ON public.main_historicalbalance USING btree (history_date);


--
-- Name: main_historicalbalance_history_user_id_65cac7f5; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbalance_history_user_id_65cac7f5 ON public.main_historicalbalance USING btree (history_user_id);


--
-- Name: main_historicalbalance_id_50c088dc; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbalance_id_50c088dc ON public.main_historicalbalance USING btree (id);


--
-- Name: main_historicalbalance_owner_id_337479c9; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbalance_owner_id_337479c9 ON public.main_historicalbalance USING btree (owner_id);


--
-- Name: main_historicalbudget_bal_id_f8c853fb; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbudget_bal_id_f8c853fb ON public.main_historicalbudget USING btree (bal_id);


--
-- Name: main_historicalbudget_category_id_b34f72d7; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbudget_category_id_b34f72d7 ON public.main_historicalbudget USING btree (category_id);


--
-- Name: main_historicalbudget_history_date_d7bcb65a; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbudget_history_date_d7bcb65a ON public.main_historicalbudget USING btree (history_date);


--
-- Name: main_historicalbudget_history_user_id_b70090f5; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbudget_history_user_id_b70090f5 ON public.main_historicalbudget USING btree (history_user_id);


--
-- Name: main_historicalbudget_id_48ad0389; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalbudget_id_48ad0389 ON public.main_historicalbudget USING btree (id);


--
-- Name: main_historicalcard_bal_id_e6644744; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcard_bal_id_e6644744 ON public.main_historicalcard USING btree (bal_id);


--
-- Name: main_historicalcard_history_date_fd332f9d; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcard_history_date_fd332f9d ON public.main_historicalcard USING btree (history_date);


--
-- Name: main_historicalcard_history_user_id_5508733a; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcard_history_user_id_5508733a ON public.main_historicalcard USING btree (history_user_id);


--
-- Name: main_historicalcard_id_6ce2cdf4; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcard_id_6ce2cdf4 ON public.main_historicalcard USING btree (id);


--
-- Name: main_historicalcard_number_663b8234; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcard_number_663b8234 ON public.main_historicalcard USING btree (number);


--
-- Name: main_historicalcard_number_663b8234_like; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcard_number_663b8234_like ON public.main_historicalcard USING btree (number varchar_pattern_ops);


--
-- Name: main_historicalcategory_history_date_77173742; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcategory_history_date_77173742 ON public.main_historicalcategory USING btree (history_date);


--
-- Name: main_historicalcategory_history_user_id_1c540f2f; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcategory_history_user_id_1c540f2f ON public.main_historicalcategory USING btree (history_user_id);


--
-- Name: main_historicalcategory_id_eb50b53f; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalcategory_id_eb50b53f ON public.main_historicalcategory USING btree (id);


--
-- Name: main_historicalnews_history_date_11bc867d; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalnews_history_date_11bc867d ON public.main_historicalnews USING btree (history_date);


--
-- Name: main_historicalnews_history_user_id_25c0a813; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalnews_history_user_id_25c0a813 ON public.main_historicalnews USING btree (history_user_id);


--
-- Name: main_historicalnews_id_b87ab8f2; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicalnews_id_b87ab8f2 ON public.main_historicalnews USING btree (id);


--
-- Name: main_historicaltransactions_bal_id_9a9caf8b; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicaltransactions_bal_id_9a9caf8b ON public.main_historicaltransactions USING btree (bal_id);


--
-- Name: main_historicaltransactions_category_id_d39c349a; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicaltransactions_category_id_d39c349a ON public.main_historicaltransactions USING btree (category_id);


--
-- Name: main_historicaltransactions_history_date_c62c8fc6; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicaltransactions_history_date_c62c8fc6 ON public.main_historicaltransactions USING btree (history_date);


--
-- Name: main_historicaltransactions_history_user_id_87524f4a; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicaltransactions_history_user_id_87524f4a ON public.main_historicaltransactions USING btree (history_user_id);


--
-- Name: main_historicaltransactions_id_a2af9e23; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_historicaltransactions_id_a2af9e23 ON public.main_historicaltransactions USING btree (id);


--
-- Name: main_transactions_bal_id_b48b8889; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_transactions_bal_id_b48b8889 ON public.main_transactions USING btree (bal_id);


--
-- Name: main_transactions_category_id_d075e714; Type: INDEX; Schema: public; Owner: zahar
--

CREATE INDEX main_transactions_category_id_d075e714 ON public.main_transactions USING btree (category_id);


--
-- Name: main_transactions pgtrigger_update_balance_on_delete_64d52; Type: TRIGGER; Schema: public; Owner: zahar
--

CREATE TRIGGER pgtrigger_update_balance_on_delete_64d52 BEFORE DELETE ON public.main_transactions FOR EACH ROW EXECUTE FUNCTION public.pgtrigger_update_balance_on_delete_64d52();


--
-- Name: TRIGGER pgtrigger_update_balance_on_delete_64d52 ON main_transactions; Type: COMMENT; Schema: public; Owner: zahar
--

COMMENT ON TRIGGER pgtrigger_update_balance_on_delete_64d52 ON public.main_transactions IS '8beede0afa9678aa0031f50f5b1c91ab7c31d549';


--
-- Name: main_transactions pgtrigger_update_balance_on_insert_e76ab; Type: TRIGGER; Schema: public; Owner: zahar
--

CREATE TRIGGER pgtrigger_update_balance_on_insert_e76ab AFTER INSERT ON public.main_transactions FOR EACH ROW EXECUTE FUNCTION public.pgtrigger_update_balance_on_insert_e76ab();


--
-- Name: TRIGGER pgtrigger_update_balance_on_insert_e76ab ON main_transactions; Type: COMMENT; Schema: public; Owner: zahar
--

COMMENT ON TRIGGER pgtrigger_update_balance_on_insert_e76ab ON public.main_transactions IS '9cda9d75ce2ff84b21999770991ba518ab5d89a1';


--
-- Name: main_transactions pgtrigger_update_balance_on_update_856d1; Type: TRIGGER; Schema: public; Owner: zahar
--

CREATE TRIGGER pgtrigger_update_balance_on_update_856d1 AFTER UPDATE ON public.main_transactions FOR EACH ROW WHEN ((old.bal_id = new.bal_id)) EXECUTE FUNCTION public.pgtrigger_update_balance_on_update_856d1();


--
-- Name: TRIGGER pgtrigger_update_balance_on_update_856d1 ON main_transactions; Type: COMMENT; Schema: public; Owner: zahar
--

COMMENT ON TRIGGER pgtrigger_update_balance_on_update_856d1 ON public.main_transactions IS 'e1b767414c00226d2998546e3a69d4207428a068';


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_balance main_balance_owner_id_6e9e9e0d_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_balance
    ADD CONSTRAINT main_balance_owner_id_6e9e9e0d_fk_auth_user_id FOREIGN KEY (owner_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_budget main_budget_bal_id_c703d1f1_fk_main_balance_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_budget
    ADD CONSTRAINT main_budget_bal_id_c703d1f1_fk_main_balance_id FOREIGN KEY (bal_id) REFERENCES public.main_balance(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_budget main_budget_category_id_5c3c66d7_fk_main_category_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_budget
    ADD CONSTRAINT main_budget_category_id_5c3c66d7_fk_main_category_id FOREIGN KEY (category_id) REFERENCES public.main_category(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_card main_card_bal_id_9622f74c_fk_main_balance_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_card
    ADD CONSTRAINT main_card_bal_id_9622f74c_fk_main_balance_id FOREIGN KEY (bal_id) REFERENCES public.main_balance(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_historicalbalance main_historicalbalance_history_user_id_65cac7f5_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalbalance
    ADD CONSTRAINT main_historicalbalance_history_user_id_65cac7f5_fk_auth_user_id FOREIGN KEY (history_user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_historicalbudget main_historicalbudget_history_user_id_b70090f5_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalbudget
    ADD CONSTRAINT main_historicalbudget_history_user_id_b70090f5_fk_auth_user_id FOREIGN KEY (history_user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_historicalcard main_historicalcard_history_user_id_5508733a_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalcard
    ADD CONSTRAINT main_historicalcard_history_user_id_5508733a_fk_auth_user_id FOREIGN KEY (history_user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_historicalcategory main_historicalcateg_history_user_id_1c540f2f_fk_auth_user; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalcategory
    ADD CONSTRAINT main_historicalcateg_history_user_id_1c540f2f_fk_auth_user FOREIGN KEY (history_user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_historicalnews main_historicalnews_history_user_id_25c0a813_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicalnews
    ADD CONSTRAINT main_historicalnews_history_user_id_25c0a813_fk_auth_user_id FOREIGN KEY (history_user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_historicaltransactions main_historicaltrans_history_user_id_87524f4a_fk_auth_user; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_historicaltransactions
    ADD CONSTRAINT main_historicaltrans_history_user_id_87524f4a_fk_auth_user FOREIGN KEY (history_user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_transactions main_transactions_bal_id_b48b8889_fk_main_balance_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_transactions
    ADD CONSTRAINT main_transactions_bal_id_b48b8889_fk_main_balance_id FOREIGN KEY (bal_id) REFERENCES public.main_balance(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: main_transactions main_transactions_category_id_d075e714_fk_main_category_id; Type: FK CONSTRAINT; Schema: public; Owner: zahar
--

ALTER TABLE ONLY public.main_transactions
    ADD CONSTRAINT main_transactions_category_id_d075e714_fk_main_category_id FOREIGN KEY (category_id) REFERENCES public.main_category(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: DATABASE project_2; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE project_2 TO zahar;
GRANT ALL ON DATABASE project_2 TO django_admin;
GRANT CONNECT ON DATABASE project_2 TO django_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA public TO django_user;
GRANT ALL ON SCHEMA public TO django_admin;


--
-- Name: TABLE auth_group; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.auth_group TO django_admin;
GRANT SELECT,INSERT ON TABLE public.auth_group TO django_user;


--
-- Name: SEQUENCE auth_group_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.auth_group_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.auth_group_id_seq TO django_user;


--
-- Name: TABLE auth_group_permissions; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.auth_group_permissions TO django_admin;
GRANT SELECT,INSERT ON TABLE public.auth_group_permissions TO django_user;


--
-- Name: SEQUENCE auth_group_permissions_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.auth_group_permissions_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.auth_group_permissions_id_seq TO django_user;


--
-- Name: TABLE auth_permission; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.auth_permission TO django_admin;
GRANT SELECT,INSERT ON TABLE public.auth_permission TO django_user;


--
-- Name: SEQUENCE auth_permission_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.auth_permission_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.auth_permission_id_seq TO django_user;


--
-- Name: TABLE auth_user; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.auth_user TO django_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE public.auth_user TO django_user;


--
-- Name: TABLE auth_user_groups; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.auth_user_groups TO django_admin;
GRANT SELECT,INSERT ON TABLE public.auth_user_groups TO django_user;


--
-- Name: SEQUENCE auth_user_groups_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.auth_user_groups_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.auth_user_groups_id_seq TO django_user;


--
-- Name: SEQUENCE auth_user_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.auth_user_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.auth_user_id_seq TO django_user;


--
-- Name: TABLE auth_user_user_permissions; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.auth_user_user_permissions TO django_admin;
GRANT SELECT,INSERT ON TABLE public.auth_user_user_permissions TO django_user;


--
-- Name: SEQUENCE auth_user_user_permissions_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.auth_user_user_permissions_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.auth_user_user_permissions_id_seq TO django_user;


--
-- Name: TABLE django_admin_log; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.django_admin_log TO django_admin;
GRANT SELECT,INSERT ON TABLE public.django_admin_log TO django_user;


--
-- Name: SEQUENCE django_admin_log_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.django_admin_log_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.django_admin_log_id_seq TO django_user;


--
-- Name: TABLE django_content_type; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.django_content_type TO django_admin;
GRANT SELECT,INSERT ON TABLE public.django_content_type TO django_user;


--
-- Name: SEQUENCE django_content_type_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.django_content_type_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.django_content_type_id_seq TO django_user;


--
-- Name: TABLE django_migrations; Type: ACL; Schema: public; Owner: zahar
--

GRANT SELECT,INSERT ON TABLE public.django_migrations TO django_user;
GRANT ALL ON TABLE public.django_migrations TO django_admin;


--
-- Name: SEQUENCE django_migrations_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.django_migrations_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.django_migrations_id_seq TO django_user;


--
-- Name: TABLE django_session; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.django_session TO django_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.django_session TO django_user;


--
-- Name: TABLE main_balance; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_balance TO django_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE public.main_balance TO django_user;


--
-- Name: SEQUENCE main_balance_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_balance_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_balance_id_seq TO django_user;


--
-- Name: TABLE main_budget; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_budget TO django_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.main_budget TO django_user;


--
-- Name: SEQUENCE main_budget_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_budget_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_budget_id_seq TO django_user;


--
-- Name: TABLE main_card; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_card TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_card TO django_user;


--
-- Name: SEQUENCE main_card_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_card_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_card_id_seq TO django_user;


--
-- Name: TABLE main_category; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_category TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_category TO django_user;


--
-- Name: SEQUENCE main_category_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_category_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_category_id_seq TO django_user;


--
-- Name: TABLE main_historicalbalance; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_historicalbalance TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_historicalbalance TO django_user;


--
-- Name: SEQUENCE main_historicalbalance_history_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_historicalbalance_history_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_historicalbalance_history_id_seq TO django_user;


--
-- Name: TABLE main_historicalbudget; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_historicalbudget TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_historicalbudget TO django_user;


--
-- Name: SEQUENCE main_historicalbudget_history_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_historicalbudget_history_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_historicalbudget_history_id_seq TO django_user;


--
-- Name: TABLE main_historicalcard; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_historicalcard TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_historicalcard TO django_user;


--
-- Name: SEQUENCE main_historicalcard_history_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_historicalcard_history_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_historicalcard_history_id_seq TO django_user;


--
-- Name: TABLE main_historicalcategory; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_historicalcategory TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_historicalcategory TO django_user;


--
-- Name: SEQUENCE main_historicalcategory_history_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_historicalcategory_history_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_historicalcategory_history_id_seq TO django_user;


--
-- Name: TABLE main_historicalnews; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_historicalnews TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_historicalnews TO django_user;


--
-- Name: SEQUENCE main_historicalnews_history_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_historicalnews_history_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_historicalnews_history_id_seq TO django_user;


--
-- Name: TABLE main_historicaltransactions; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_historicaltransactions TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_historicaltransactions TO django_user;


--
-- Name: SEQUENCE main_historicaltransactions_history_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_historicaltransactions_history_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_historicaltransactions_history_id_seq TO django_user;


--
-- Name: TABLE main_news; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_news TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_news TO django_user;


--
-- Name: SEQUENCE main_news_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_news_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_news_id_seq TO django_user;


--
-- Name: TABLE main_transactions; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.main_transactions TO django_admin;
GRANT SELECT,INSERT ON TABLE public.main_transactions TO django_user;


--
-- Name: SEQUENCE main_transactions_id_seq; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON SEQUENCE public.main_transactions_id_seq TO django_admin;
GRANT ALL ON SEQUENCE public.main_transactions_id_seq TO django_user;


--
-- Name: TABLE vw_user_transactions; Type: ACL; Schema: public; Owner: zahar
--

GRANT ALL ON TABLE public.vw_user_transactions TO django_admin;
GRANT SELECT,INSERT ON TABLE public.vw_user_transactions TO django_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO django_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: zahar
--

ALTER DEFAULT PRIVILEGES FOR ROLE zahar IN SCHEMA public GRANT ALL ON SEQUENCES  TO django_admin;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO django_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: zahar
--

ALTER DEFAULT PRIVILEGES FOR ROLE zahar IN SCHEMA public GRANT ALL ON TABLES  TO django_admin;


--
-- PostgreSQL database dump complete
--

\unrestrict poKBtu3Z3zYyy0ZjSUDCSVcJdWv1emRQfUIStfZwqFIGDyXQJbfu3LUg688Kj3r

